require 'spec_helper'

describe API::V2::GraphqlController do
  let(:admin) { create(:administrateur) }
  let(:token) { admin.renew_api_token }
  let(:procedure) { create(:procedure, :published, :for_individual, :with_service, :with_all_champs, administrateurs: [admin]) }
  let(:dossier) do
    dossier = create(:dossier,
      :en_construction,
      :with_all_champs,
      :for_individual,
      procedure: procedure)
    create(:commentaire, :with_file, dossier: dossier, email: 'test@test.com')
    dossier
  end
  let(:dossier1) { create(:dossier, :en_construction, :for_individual, procedure: procedure, en_construction_at: 1.day.ago) }
  let(:dossier2) { create(:dossier, :en_construction, :for_individual, procedure: procedure, en_construction_at: 3.days.ago) }
  let!(:dossier_brouillon) { create(:dossier, :for_individual, procedure: procedure) }
  let(:dossiers) { [dossier2, dossier1, dossier] }
  let(:instructeur) { create(:instructeur, followed_dossiers: dossiers) }

  before do
    instructeur.assign_to_procedure(procedure)
  end

  let(:query) do
    "{
      demarche(number: #{procedure.id}) {
        id
        number
        title
        description
        state
        dateCreation
        dateDerniereModification
        dateFermeture
        groupeInstructeurs {
          label
          instructeurs {
            email
          }
        }
        service {
          nom
          typeOrganisme
          organisme
        }
        champDescriptors {
          id
          type
          label
          description
          required
        }
        dossiers {
          nodes {
            id
          }
        }
      }
    }"
  end
  let(:body) { JSON.parse(subject.body, symbolize_names: true) }
  let(:gql_data) { body[:data] }
  let(:gql_errors) { body[:errors] }

  subject { post :execute, params: { query: query } }

  before do
    Flipper.enable(:administrateur_graphql, admin.user)
  end

  context "when authenticated" do
    let(:authorization_header) { ActionController::HttpAuthentication::Token.encode_credentials(token) }

    before do
      request.env['HTTP_AUTHORIZATION'] = authorization_header
    end

    context "demarche" do
      it "should be returned" do
        expect(gql_errors).to eq(nil)
        expect(gql_data).to eq(demarche: {
          id: procedure.to_typed_id,
          number: procedure.id,
          title: procedure.libelle,
          description: procedure.description,
          state: 'publiee',
          dateFermeture: nil,
          dateCreation: procedure.created_at.iso8601,
          dateDerniereModification: procedure.updated_at.iso8601,
          groupeInstructeurs: [
            {
              instructeurs: [{ email: instructeur.email }],
              label: "défaut"
            }
          ],
          service: {
            nom: procedure.service.nom,
            typeOrganisme: procedure.service.type_organisme,
            organisme: procedure.service.organisme
          },
          champDescriptors: procedure.types_de_champ.map do |tdc|
            {
              id: tdc.to_typed_id,
              label: tdc.libelle,
              type: tdc.type_champ,
              description: tdc.description,
              required: tdc.mandatory?
            }
          end,
          dossiers: {
            nodes: dossiers.map { |dossier| { id: dossier.to_typed_id } }
          }
        })
      end

      context "filter dossiers" do
        let(:query) do
          "{
            demarche(number: #{procedure.id}) {
              id
              number
              dossiers(createdSince: \"#{2.days.ago.iso8601}\") {
                nodes {
                  id
                }
              }
            }
          }"
        end

        it "should be returned" do
          expect(gql_errors).to eq(nil)
          expect(gql_data).to eq(demarche: {
            id: procedure.to_typed_id,
            number: procedure.id,
            dossiers: {
              nodes: [{ id: dossier1.to_typed_id }, { id: dossier.to_typed_id }]
            }
          })
        end
      end
    end

    context "dossier" do
      let(:query) do
        "{
          dossier(number: #{dossier.id}) {
            id
            number
            state
            dateDerniereModification
            datePassageEnConstruction
            datePassageEnInstruction
            dateTraitement
            motivation
            motivationAttachment {
              url
            }
            usager {
              id
              email
            }
            demandeur {
              id
              ... on PersonnePhysique {
                nom
                prenom
                civilite
                dateDeNaissance
              }
            }
            instructeurs {
              id
              email
            }
            messages {
              email
              body
              attachment {
                filename
                checksum
                byteSize
                contentType
                url
              }
            }
            avis {
              expert {
                email
              }
              question
              reponse
              dateQuestion
              dateReponse
              attachment {
                url
                filename
              }
            }
            champs {
              id
              label
              stringValue
            }
          }
        }"
      end

      context "with individual" do
        it "should be returned" do
          expect(gql_errors).to eq(nil)
          expect(gql_data).to eq(dossier: {
            id: dossier.to_typed_id,
            number: dossier.id,
            state: 'en_construction',
            dateDerniereModification: dossier.updated_at.iso8601,
            datePassageEnConstruction: dossier.en_construction_at.iso8601,
            datePassageEnInstruction: nil,
            dateTraitement: nil,
            motivation: nil,
            motivationAttachment: nil,
            usager: {
              id: dossier.user.to_typed_id,
              email: dossier.user.email
            },
            instructeurs: [
              {
                id: instructeur.to_typed_id,
                email: instructeur.email
              }
            ],
            demandeur: {
              id: dossier.individual.to_typed_id,
              nom: dossier.individual.nom,
              prenom: dossier.individual.prenom,
              civilite: 'M',
              dateDeNaissance: '1991-11-01'
            },
            messages: dossier.commentaires.map do |commentaire|
              {
                body: commentaire.body,
                attachment: {
                  filename: commentaire.piece_jointe.filename.to_s,
                  contentType: commentaire.piece_jointe.content_type,
                  checksum: commentaire.piece_jointe.checksum,
                  byteSize: commentaire.piece_jointe.byte_size,
                  url: Rails.application.routes.url_helpers.url_for(commentaire.piece_jointe)
                },
                email: commentaire.email
              }
            end,
            avis: [],
            champs: dossier.champs.map do |champ|
              {
                id: champ.to_typed_id,
                label: champ.libelle,
                stringValue: champ.for_api_v2
              }
            end
          })
          expect(gql_data[:dossier][:champs][0][:id]).to eq(dossier.champs[0].type_de_champ.to_typed_id)
        end
      end

      context "with entreprise" do
        let(:procedure) { create(:procedure, :published, administrateurs: [admin]) }
        let(:dossier) { create(:dossier, :en_construction, :with_entreprise, procedure: procedure) }

        let(:query) do
          "{
            dossier(number: #{dossier.id}) {
              id
              number
              usager {
                id
                email
              }
              demandeur {
                id
                ... on PersonneMorale {
                  siret
                  siegeSocial
                  entreprise {
                    siren
                    dateCreation
                  }
                }
              }
            }
          }"
        end

        it "should be returned" do
          expect(gql_errors).to eq(nil)
          expect(gql_data).to eq(dossier: {
            id: dossier.to_typed_id,
            number: dossier.id,
            usager: {
              id: dossier.user.to_typed_id,
              email: dossier.user.email
            },
            demandeur: {
              id: dossier.etablissement.to_typed_id,
              siret: dossier.etablissement.siret,
              siegeSocial: dossier.etablissement.siege_social,
              entreprise: {
                siren: dossier.etablissement.entreprise_siren,
                dateCreation: dossier.etablissement.entreprise_date_creation.iso8601
              }
            }
          })
        end
      end
    end

    context "mutations" do
      describe 'dossierEnvoyerMessage' do
        context 'success' do
          let(:query) do
            "mutation {
              dossierEnvoyerMessage(input: {
                dossierId: \"#{dossier.to_typed_id}\",
                instructeurId: \"#{instructeur.to_typed_id}\",
                body: \"Bonjour\"
              }) {
                message {
                  body
                }
              }
            }"
          end

          it "should post a message" do
            expect(gql_errors).to eq(nil)

            expect(gql_data).to eq(dossierEnvoyerMessage: {
              message: {
                body: "Bonjour"
              }
            })
          end
        end

        context 'schema error' do
          let(:query) do
            "mutation {
              dossierEnvoyerMessage(input: {
                dossierId: \"#{dossier.to_typed_id}\",
                instructeurId: \"#{instructeur.to_typed_id}\"
              }) {
                message {
                  body
                }
              }
            }"
          end

          it "should fail" do
            expect(gql_data).to eq(nil)
            expect(gql_errors).not_to eq(nil)
          end
        end

        context 'validation error' do
          let(:query) do
            "mutation {
              dossierEnvoyerMessage(input: {
                dossierId: \"#{dossier.to_typed_id}\",
                instructeurId: \"#{instructeur.to_typed_id}\",
                body: \"\"
              }) {
                message {
                  body
                }
                errors {
                  message
                }
              }
            }"
          end

          it "should fail" do
            expect(gql_errors).to eq(nil)
            expect(gql_data).to eq(dossierEnvoyerMessage: {
              errors: [{ message: "Votre message ne peut être vide" }],
              message: nil
            })
          end
        end
      end

      describe 'dossierPasserEnInstruction' do
        let(:dossier) { create(:dossier, :en_construction, :for_individual, procedure: procedure) }
        let(:query) do
          "mutation {
            dossierPasserEnInstruction(input: {
              dossierId: \"#{dossier.to_typed_id}\",
              instructeurId: \"#{instructeur.to_typed_id}\"
            }) {
              dossier {
                id
                state
                motivation
              }
              errors {
                message
              }
            }
          }"
        end

        context 'success' do
          it "should passer en instruction dossier" do
            expect(gql_errors).to eq(nil)

            expect(gql_data).to eq(dossierPasserEnInstruction: {
              dossier: {
                id: dossier.to_typed_id,
                state: "en_instruction",
                motivation: nil
              },
              errors: nil
            })
          end
        end

        context 'validation error' do
          let(:dossier) { create(:dossier, :en_instruction, :for_individual, procedure: procedure) }

          it "should fail" do
            expect(gql_errors).to eq(nil)
            expect(gql_data).to eq(dossierPasserEnInstruction: {
              errors: [{ message: "Le dossier est déjà en instruction" }],
              dossier: nil
            })
          end
        end
      end

      describe 'dossierClasserSansSuite' do
        let(:dossier) { create(:dossier, :en_instruction, :for_individual, procedure: procedure) }
        let(:query) do
          "mutation {
            dossierClasserSansSuite(input: {
              dossierId: \"#{dossier.to_typed_id}\",
              instructeurId: \"#{instructeur.to_typed_id}\",
              motivation: \"Parce que\"
            }) {
              dossier {
                id
                state
                motivation
              }
              errors {
                message
              }
            }
          }"
        end

        context 'success' do
          it "should classer sans suite dossier" do
            expect(gql_errors).to eq(nil)

            expect(gql_data).to eq(dossierClasserSansSuite: {
              dossier: {
                id: dossier.to_typed_id,
                state: "sans_suite",
                motivation: "Parce que"
              },
              errors: nil
            })
          end
        end

        context 'validation error' do
          let(:dossier) { create(:dossier, :accepte, :for_individual, procedure: procedure) }

          it "should fail" do
            expect(gql_errors).to eq(nil)
            expect(gql_data).to eq(dossierClasserSansSuite: {
              errors: [{ message: "Le dossier est déjà accepté" }],
              dossier: nil
            })
          end
        end
      end

      describe 'dossierRefuser' do
        let(:dossier) { create(:dossier, :en_instruction, :for_individual, procedure: procedure) }
        let(:query) do
          "mutation {
            dossierRefuser(input: {
              dossierId: \"#{dossier.to_typed_id}\",
              instructeurId: \"#{instructeur.to_typed_id}\",
              motivation: \"Parce que\"
            }) {
              dossier {
                id
                state
                motivation
              }
              errors {
                message
              }
            }
          }"
        end

        context 'success' do
          it "should refuser dossier" do
            expect(gql_errors).to eq(nil)

            expect(gql_data).to eq(dossierRefuser: {
              dossier: {
                id: dossier.to_typed_id,
                state: "refuse",
                motivation: "Parce que"
              },
              errors: nil
            })
          end
        end

        context 'validation error' do
          let(:dossier) { create(:dossier, :sans_suite, :for_individual, procedure: procedure) }

          it "should fail" do
            expect(gql_errors).to eq(nil)
            expect(gql_data).to eq(dossierRefuser: {
              errors: [{ message: "Le dossier est déjà sans suite" }],
              dossier: nil
            })
          end
        end
      end

      describe 'dossierAccepter' do
        let(:dossier) { create(:dossier, :en_instruction, :for_individual, procedure: procedure) }
        let(:query) do
          "mutation {
            dossierAccepter(input: {
              dossierId: \"#{dossier.to_typed_id}\",
              instructeurId: \"#{instructeur.to_typed_id}\",
              motivation: \"Parce que\"
            }) {
              dossier {
                id
                state
                motivation
              }
              errors {
                message
              }
            }
          }"
        end

        context 'success' do
          it "should accepter dossier" do
            expect(gql_errors).to eq(nil)

            expect(gql_data).to eq(dossierAccepter: {
              dossier: {
                id: dossier.to_typed_id,
                state: "accepte",
                motivation: "Parce que"
              },
              errors: nil
            })
          end
        end

        context 'success without motivation' do
          let(:query) do
            "mutation {
              dossierAccepter(input: {
                dossierId: \"#{dossier.to_typed_id}\",
                instructeurId: \"#{instructeur.to_typed_id}\"
              }) {
                dossier {
                  id
                  state
                  motivation
                }
                errors {
                  message
                }
              }
            }"
          end

          it "should accepter dossier" do
            expect(gql_errors).to eq(nil)

            expect(gql_data).to eq(dossierAccepter: {
              dossier: {
                id: dossier.to_typed_id,
                state: "accepte",
                motivation: nil
              },
              errors: nil
            })
          end
        end

        context 'validation error' do
          let(:dossier) { create(:dossier, :refuse, :for_individual, procedure: procedure) }

          it "should fail" do
            expect(gql_errors).to eq(nil)
            expect(gql_data).to eq(dossierAccepter: {
              errors: [{ message: "Le dossier est déjà refusé" }],
              dossier: nil
            })
          end
        end
      end

      describe 'createDirectUpload' do
        let(:query) do
          "mutation {
            createDirectUpload(input: {
              dossierId: \"#{dossier.to_typed_id}\",
              filename: \"hello.png\",
              byteSize: 1234,
              checksum: \"qwerty1234\",
              contentType: \"image/png\"
            }) {
              directUpload {
                url
                headers
                blobId
                signedBlobId
              }
            }
          }"
        end

        it "should initiate a direct upload" do
          expect(gql_errors).to eq(nil)

          data = gql_data[:createDirectUpload][:directUpload]
          expect(data[:url]).not_to be_nil
          expect(data[:headers]).not_to be_nil
          expect(data[:blobId]).not_to be_nil
          expect(data[:signedBlobId]).not_to be_nil
        end
      end
    end
  end

  context "when not authenticated" do
    it "should return error" do
      expect(gql_data).to eq(nil)
      expect(gql_errors).not_to eq(nil)
    end

    context "dossier" do
      let(:query) { "{ dossier(number: #{dossier.id}) { id number usager { email } } }" }

      it "should return error" do
        expect(gql_data).to eq(nil)
        expect(gql_errors).not_to eq(nil)
      end
    end

    context "mutation" do
      let(:query) do
        "mutation {
          dossierEnvoyerMessage(input: {
            dossierId: \"#{dossier.to_typed_id}\",
            instructeurId: \"#{instructeur.to_typed_id}\",
            body: \"Bonjour\"
          }) {
            message {
              body
            }
          }
        }"
      end

      it "should return error" do
        expect(gql_data[:dossierEnvoyerMessage]).to eq(nil)
        expect(gql_errors).not_to eq(nil)
      end
    end
  end
end
