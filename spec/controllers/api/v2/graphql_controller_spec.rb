describe API::V2::GraphqlController do
  let(:admin) { create(:administrateur) }
  let(:token) { admin.renew_api_token }
  let(:procedure) { create(:procedure, :published, :for_individual, :with_service, :with_all_champs, :with_all_annotations, administrateurs: [admin]) }
  let(:dossier) do
    dossier = create(:dossier,
      :en_construction,
      :with_all_champs,
      :with_all_annotations,
      :with_individual,
      procedure: procedure)
    create(:commentaire, :with_file, dossier: dossier, email: 'test@test.com')
    dossier
  end
  let(:dossier1) { create(:dossier, :en_construction, :with_individual, procedure: procedure, en_construction_at: 1.day.ago) }
  let(:dossier2) { create(:dossier, :en_construction, :with_individual, :archived, procedure: procedure, en_construction_at: 3.days.ago) }
  let(:dossier_brouillon) { create(:dossier, :with_individual, procedure: procedure) }
  let(:dossiers) { [dossier2, dossier1, dossier] }
  let(:instructeur) { create(:instructeur, followed_dossiers: dossiers) }

  def compute_checksum_in_chunks(io)
    Digest::MD5.new.tap do |checksum|
      while (chunk = io.read(5.megabytes))
        checksum << chunk
      end

      io.rewind
    end.base64digest
  end

  let(:file) { fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png') }
  let(:blob_info) do
    {
      filename: file.original_filename,
      byte_size: file.size,
      checksum: compute_checksum_in_chunks(file),
      content_type: file.content_type
    }
  end
  let(:blob) do
    blob = ActiveStorage::Blob.create_before_direct_upload!(**blob_info)
    blob.upload(file)
    blob
  end

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
        revisions {
          id
        }
        draftRevision {
          id
        }
        publishedRevision {
          id
          champDescriptors {
            type
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
          champDescriptors {
            id
            type
          }
          options
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
          revisions: procedure.revisions.map { |revision| { id: revision.to_typed_id } },
          draftRevision: { id: procedure.draft_revision.to_typed_id },
          publishedRevision: {
            id: procedure.published_revision.to_typed_id,
            champDescriptors: procedure.published_types_de_champ.map do |tdc|
              {
                type: tdc.type_champ
              }
            end
          },
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
              required: tdc.mandatory?,
              champDescriptors: tdc.repetition? ? tdc.reload.types_de_champ.map { |tdc| { id: tdc.to_typed_id, type: tdc.type_champ } } : nil,
              options: tdc.drop_down_list? ? tdc.drop_down_list_options.reject(&:empty?) : nil
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

      context "filter archived dossiers" do
        let(:query) do
          "{
            demarche(number: #{procedure.id}) {
              id
              number
              dossiers(archived: #{archived_filter}) {
                nodes {
                  id
                }
              }
            }
          }"
        end

        context 'with archived=true' do
          let(:archived_filter) { 'true' }
          it "only archived dossiers should be returned" do
            expect(gql_errors).to eq(nil)
            expect(gql_data).to eq(demarche: {
              id: procedure.to_typed_id,
              number: procedure.id,
              dossiers: {
                nodes: [{ id: dossier2.to_typed_id }]
              }
            })
          end
        end

        context 'with archived=false' do
          let(:archived_filter) { 'false' }
          it "only not archived dossiers should be returned" do
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
    end

    context "dossier" do
      context "with individual" do
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
              groupeInstructeur {
                id
                number
                label
              }
              revision {
                id
                champDescriptors {
                  type
                }
              }
              messages {
                email
                body
                attachment {
                  filename
                  checksum
                  byteSize
                  contentType
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
            groupeInstructeur: {
              id: dossier.groupe_instructeur.to_typed_id,
              number: dossier.groupe_instructeur.id,
              label: dossier.groupe_instructeur.label
            },
            revision: {
              id: dossier.revision.to_typed_id,
              champDescriptors: dossier.types_de_champ.map do |tdc|
                {
                  type: tdc.type_champ
                }
              end
            },
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
                  byteSize: commentaire.piece_jointe.byte_size
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
        let(:procedure_for_entreprise) { create(:procedure, :published, administrateurs: [admin]) }
        let(:dossier) { create(:dossier, :en_construction, :with_entreprise, procedure: procedure_for_entreprise) }

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
                  numeroVoie
                  typeVoie
                  entreprise {
                    siren
                    dateCreation
                    capitalSocial
                    codeEffectifEntreprise
                  }
                }
              }
            }
          }"
        end

        context "in the nominal case" do
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
                numeroVoie: dossier.etablissement.numero_voie.to_s,
                typeVoie: dossier.etablissement.type_voie.to_s,
                entreprise: {
                  siren: dossier.etablissement.entreprise_siren,
                  dateCreation: dossier.etablissement.entreprise_date_creation.iso8601,
                  capitalSocial: dossier.etablissement.entreprise_capital_social.to_s,
                  codeEffectifEntreprise: dossier.etablissement.entreprise_code_effectif_entreprise.to_s
                }
              }
            })
          end
        end

        context "with links" do
          let(:dossier) { create(:dossier, :accepte, :with_attestation, procedure: procedure) }
          let(:query) do
            "{
              dossier(number: #{dossier.id}) {
                id
                number
                pdf {
                  url
                }
                geojson {
                  url
                }
                attestation {
                  url
                }
              }
            }"
          end

          it "urls should be returned" do
            expect(gql_errors).to eq(nil)

            expect(gql_data[:dossier][:pdf][:url]).not_to be_nil
            expect(gql_data[:dossier][:geojson][:url]).not_to be_nil
            expect(gql_data[:dossier][:attestation][:url]).not_to be_nil
          end
        end

        context "when there are missing data" do
          before do
            dossier.etablissement.update!(entreprise_code_effectif_entreprise: nil, entreprise_capital_social: nil,
                                          numero_voie: nil, type_voie: nil)
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
                numeroVoie: nil,
                typeVoie: nil,
                entreprise: {
                  siren: dossier.etablissement.entreprise_siren,
                  dateCreation: dossier.etablissement.entreprise_date_creation.iso8601,
                  capitalSocial: '-1',
                  codeEffectifEntreprise: nil
                }
              }
            })
          end
        end
      end

      context "champs" do
        let(:procedure) { create(:procedure, :published, :for_individual, administrateurs: [admin], types_de_champ: [type_de_champ_date, type_de_champ_datetime]) }
        let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
        let(:type_de_champ_date) { build(:type_de_champ_date) }
        let(:type_de_champ_datetime) { build(:type_de_champ_datetime) }
        let(:champ_date) { dossier.champs.first }
        let(:champ_datetime) { dossier.champs.second }
        let(:date) { '2019-07-10' }
        let(:datetime) { '15/09/1962 15:35' }

        before do
          champ_date.update(value: date)
          champ_datetime.update(value: datetime)
        end

        context "with Date" do
          let(:query) do
            "{
              dossier(number: #{dossier.id}) {
                champs {
                  id
                  label
                  ... on DateChamp {
                    value
                  }
                }
              }
            }"
          end

          it "should be returned" do
            expect(gql_errors).to eq(nil)
            expect(gql_data).to eq(dossier: {
              champs: [
                {
                  id: champ_date.to_typed_id,
                  label: champ_date.libelle,
                  value: Time.zone.parse(date).iso8601
                },
                {
                  id: champ_datetime.to_typed_id,
                  label: champ_datetime.libelle,
                  value: Time.zone.parse(datetime).iso8601
                }
              ]
            })
          end
        end

        context "with Datetime" do
          let(:query) do
            "{
              dossier(number: #{dossier.id}) {
                champs {
                  id
                  label
                  ... on DateChamp {
                    value
                    date
                  }
                  ... on DatetimeChamp {
                    datetime
                  }
                }
              }
            }"
          end

          it "should be returned" do
            expect(gql_errors).to eq(nil)
            expect(gql_data).to eq(dossier: {
              champs: [
                {
                  id: champ_date.to_typed_id,
                  label: champ_date.libelle,
                  value: '2019-07-10T00:00:00-10:00',
                  date: '2019-07-10'
                },
                {
                  id: champ_datetime.to_typed_id,
                  label: champ_datetime.libelle,
                  datetime: '1962-09-15T15:35:00-10:00'
                }
              ]
            })
          end
        end
      end
    end

    context "groupeInstructeur" do
      let(:groupe_instructeur) { procedure.groupe_instructeurs.first }
      let(:query) do
        "{
          groupeInstructeur(number: #{groupe_instructeur.id}) {
            id
            number
            label
            dossiers {
              nodes {
                id
              }
            }
          }
        }"
      end

      it "should be returned" do
        expect(gql_errors).to eq(nil)
        expect(gql_data).to eq(groupeInstructeur: {
          id: groupe_instructeur.to_typed_id,
          number: groupe_instructeur.id,
          label: groupe_instructeur.label,
          dossiers: {
            nodes: dossiers.map { |dossier| { id: dossier.to_typed_id } }
          }
        })
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
                body: \"Bonjour\",
                attachment: \"#{blob.signed_id}\"
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

        context 'upload error' do
          let(:query) do
            "mutation {
              dossierEnvoyerMessage(input: {
                dossierId: \"#{dossier.to_typed_id}\",
                instructeurId: \"#{instructeur.to_typed_id}\",
                body: \"Hello world\",
                attachment: \"fake\"
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
              errors: [{ message: "L’identifiant du fichier téléversé est invalide" }],
              message: nil
            })
          end
        end
      end

      describe 'dossierPasserEnInstruction' do
        let(:dossier) { create(:dossier, :en_construction, :with_individual, procedure: procedure) }
        let(:instructeur_id) { instructeur.to_typed_id }
        let(:query) do
          "mutation {
            dossierPasserEnInstruction(input: {
              dossierId: \"#{dossier.to_typed_id}\",
              instructeurId: \"#{instructeur_id}\"
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
          let(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure: procedure) }

          it "should fail" do
            expect(gql_errors).to eq(nil)
            expect(gql_data).to eq(dossierPasserEnInstruction: {
              errors: [{ message: "Le dossier est déjà en instruction" }],
              dossier: nil
            })
          end
        end

        context 'instructeur error' do
          let(:instructeur_id) { create(:instructeur).to_typed_id }

          it "should fail" do
            expect(gql_errors).to eq(nil)
            expect(gql_data).to eq(dossierPasserEnInstruction: {
              errors: [{ message: 'L’instructeur n’a pas les droits d’accès à ce dossier' }],
              dossier: nil
            })
          end
        end
      end

      describe 'dossierRepasserEnInstruction' do
        let(:dossier) { create(:dossier, :accepte, :with_individual, procedure: procedure) }
        let(:instructeur_id) { instructeur.to_typed_id }
        let(:query) do
          "mutation {
            dossierRepasserEnInstruction(input: {
              dossierId: \"#{dossier.to_typed_id}\",
              instructeurId: \"#{instructeur_id}\"
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
          it "should repasser en instruction dossier" do
            expect(gql_errors).to eq(nil)

            expect(gql_data).to eq(dossierRepasserEnInstruction: {
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
          let(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure: procedure) }

          it "should fail" do
            expect(gql_errors).to eq(nil)
            expect(gql_data).to eq(dossierRepasserEnInstruction: {
              errors: [{ message: "Le dossier ne peut repasser en instruction lorsqu'il est en instruction" }],
              dossier: nil
            })
          end
        end

        context 'instructeur error' do
          let(:instructeur_id) { create(:instructeur).to_typed_id }

          it "should fail" do
            expect(gql_errors).to eq(nil)
            expect(gql_data).to eq(dossierRepasserEnInstruction: {
              errors: [{ message: 'L’instructeur n’a pas les droits d’accès à ce dossier' }],
              dossier: nil
            })
          end
        end
      end

      describe 'dossierClasserSansSuite' do
        let(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure: procedure) }
        let(:query) do
          "mutation {
            dossierClasserSansSuite(input: {
              dossierId: \"#{dossier.to_typed_id}\",
              instructeurId: \"#{instructeur.to_typed_id}\",
              motivation: \"Parce que\",
              justificatif: \"#{blob.signed_id}\"
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
          let(:dossier) { create(:dossier, :accepte, :with_individual, procedure: procedure) }

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
        let(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure: procedure) }
        let(:query) do
          "mutation {
            dossierRefuser(input: {
              dossierId: \"#{dossier.to_typed_id}\",
              instructeurId: \"#{instructeur.to_typed_id}\",
              motivation: \"Parce que\",
              justificatif: \"#{blob.signed_id}\"
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
          let(:dossier) { create(:dossier, :sans_suite, :with_individual, procedure: procedure) }

          it "should fail" do
            expect(gql_errors).to eq(nil)
            expect(gql_data).to eq(dossierRefuser: {
              errors: [{ message: "Le dossier est déjà classé sans suite" }],
              dossier: nil
            })
          end
        end
      end

      describe 'dossierAccepter' do
        let(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure: procedure) }
        let(:query) do
          "mutation {
            dossierAccepter(input: {
              dossierId: \"#{dossier.to_typed_id}\",
              instructeurId: \"#{instructeur.to_typed_id}\",
              motivation: \"Parce que\",
              justificatif: \"#{blob.signed_id}\"
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
          let(:dossier) { create(:dossier, :refuse, :with_individual, procedure: procedure) }

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
              filename: \"#{blob_info[:filename]}\",
              byteSize: #{blob_info[:byte_size]},
              checksum: \"#{blob_info[:checksum]}\",
              contentType: \"#{blob_info[:content_type]}\"
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

        let(:attach_query) do
          "mutation {
            dossierEnvoyerMessage(input: {
              dossierId: \"#{dossier.to_typed_id}\",
              instructeurId: \"#{instructeur.to_typed_id}\",
              body: \"Hello world\",
              attachment: \"#{direct_upload_blob_id}\"
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
        let(:attach_query_exec) { post :execute, params: { query: attach_query } }
        let(:attach_query_body) { JSON.parse(attach_query_exec.body, symbolize_names: true) }
        let(:attach_query_data) { attach_query_body[:data] }
        let(:direct_upload_data) { gql_data[:createDirectUpload][:directUpload] }
        let(:direct_upload_blob_id) { direct_upload_data[:signedBlobId] }

        it "should initiate a direct upload" do
          expect(gql_errors).to eq(nil)

          data = gql_data[:createDirectUpload][:directUpload]
          expect(data[:url]).not_to be_nil
          expect(data[:headers]).not_to be_nil
          expect(data[:blobId]).not_to be_nil
          expect(data[:signedBlobId]).not_to be_nil
        end

        it "wrong hash error" do
          blob = ActiveStorage::Blob.find direct_upload_data[:blobId]
          blob.service.upload blob.key, StringIO.new('toto')
          expect(attach_query_data).to eq(dossierEnvoyerMessage: {
            errors: [{ message: "Le hash du fichier téléversé est invalide" }],
            message: nil
          })
        end
      end

      describe 'dossierChangerGroupeInstructeur' do
        let(:query) do
          "mutation {
            dossierChangerGroupeInstructeur(input: {
              dossierId: \"#{dossier.to_typed_id}\",
              groupeInstructeurId: \"#{dossier.groupe_instructeur.to_typed_id}\"
            }) {
              errors {
                message
              }
            }
          }"
        end

        it "validation error" do
          expect(gql_errors).to eq(nil)

          expect(gql_data).to eq(dossierChangerGroupeInstructeur: {
            errors: [{ message: "Le dossier est déjà avec le grope instructeur: 'défaut'" }]
          })
        end

        context "should changer groupe instructeur" do
          let!(:new_groupe_instructeur) { procedure.groupe_instructeurs.create(label: 'new groupe instructeur') }
          let(:query) do
            "mutation {
            dossierChangerGroupeInstructeur(input: {
              dossierId: \"#{dossier.to_typed_id}\",
              groupeInstructeurId: \"#{new_groupe_instructeur.to_typed_id}\"
            }) {
              errors {
                message
              }
            }
          }"
          end

          it "change made" do
            expect(gql_errors).to eq(nil)

            expect(gql_data).to eq(dossierChangerGroupeInstructeur: {
              errors: nil
            })
          end
        end
      end

      describe 'dossierArchiver' do
        let(:query) do
          "mutation {
            dossierArchiver(input: {
              dossierId: \"#{dossier.to_typed_id}\",
              instructeurId: \"#{instructeur.to_typed_id}\"
            }) {
              dossier {
                archived
              }
              errors {
                message
              }
            }
          }"
        end

        it "validation error" do
          expect(gql_errors).to eq(nil)

          expect(gql_data).to eq(dossierArchiver: {
            dossier: nil,
            errors: [{ message: "Un dossier ne peut être archivé qu’une fois le traitement terminé" }]
          })
        end

        context "should archive dossier" do
          let(:dossier) { create(:dossier, :sans_suite, :with_individual, procedure: procedure) }

          it "change made" do
            expect(gql_errors).to eq(nil)

            expect(gql_data).to eq(dossierArchiver: {
              dossier: {
                archived: true
              },
              errors: nil
            })
          end
        end
      end

      describe 'dossierModifierAnnotation' do
        describe 'text' do
          let(:query) do
            "mutation {
              dossierModifierAnnotationText(input: {
                dossierId: \"#{dossier.to_typed_id}\",
                annotationId: \"#{dossier.champs_private.first.to_typed_id}\",
                instructeurId: \"#{instructeur.to_typed_id}\",
                value: \"hello\"
              }) {
                annotation {
                  stringValue
                }
                errors {
                  message
                }
              }
            }"
          end

          context "success" do
            it 'should be a success' do
              expect(gql_errors).to eq(nil)

              expect(gql_data).to eq(dossierModifierAnnotationText: {
                annotation: {
                  stringValue: 'hello'
                },
                errors: nil
              })
            end
          end
        end

        describe 'checkbox' do
          let(:value) { 'true' }

          let(:query) do
            "mutation {
              dossierModifierAnnotationCheckbox(input: {
                dossierId: \"#{dossier.to_typed_id}\",
                annotationId: \"#{dossier.champs_private.find { |c| c.type_champ == 'checkbox' }.to_typed_id}\",
                instructeurId: \"#{instructeur.to_typed_id}\",
                value: #{value}
              }) {
                annotation {
                  stringValue
                }
                errors {
                  message
                }
              }
            }"
          end

          context "success when true" do
            it 'should be a success' do
              expect(gql_errors).to eq(nil)

              expect(gql_data).to eq(dossierModifierAnnotationCheckbox: {
                annotation: {
                  stringValue: 'true'
                },
                errors: nil
              })
            end
          end

          context "success when false" do
            let(:value) { 'false' }

            it 'should be a success' do
              expect(gql_errors).to eq(nil)

              expect(gql_data).to eq(dossierModifierAnnotationCheckbox: {
                annotation: {
                  stringValue: 'false'
                },
                errors: nil
              })
            end
          end
        end

        describe 'yes_no' do
          let(:value) { 'true' }

          let(:query) do
            "mutation {
              dossierModifierAnnotationCheckbox(input: {
                dossierId: \"#{dossier.to_typed_id}\",
                annotationId: \"#{dossier.champs_private.find { |c| c.type_champ == 'yes_no' }.to_typed_id}\",
                instructeurId: \"#{instructeur.to_typed_id}\",
                value: #{value}
              }) {
                annotation {
                  stringValue
                }
                errors {
                  message
                }
              }
            }"
          end

          context "success when true" do
            it 'should be a success' do
              expect(gql_errors).to eq(nil)

              expect(gql_data).to eq(dossierModifierAnnotationCheckbox: {
                annotation: {
                  stringValue: 'true'
                },
                errors: nil
              })
            end
          end

          context "success when false" do
            let(:value) { 'false' }

            it 'should be a success' do
              expect(gql_errors).to eq(nil)

              expect(gql_data).to eq(dossierModifierAnnotationCheckbox: {
                annotation: {
                  stringValue: 'false'
                },
                errors: nil
              })
            end
          end
        end

        describe 'date' do
          let(:query) do
            "mutation {
              dossierModifierAnnotationDate(input: {
                dossierId: \"#{dossier.to_typed_id}\",
                annotationId: \"#{dossier.champs_private.find { |c| c.type_champ == 'date' }.to_typed_id}\",
                instructeurId: \"#{instructeur.to_typed_id}\",
                value: \"#{1.day.from_now.to_date.iso8601}\"
              }) {
                annotation {
                  stringValue
                }
                errors {
                  message
                }
              }
            }"
          end

          context "success" do
            it 'should be a success' do
              expect(gql_errors).to eq(nil)

              expect(gql_data).to eq(dossierModifierAnnotationDate: {
                annotation: {
                  stringValue: dossier.reload.champs_private.find { |c| c.type_champ == 'date' }.to_s
                },
                errors: nil
              })
            end
          end
        end

        describe 'datetime' do
          let(:query) do
            "mutation {
              dossierModifierAnnotationDatetime(input: {
                dossierId: \"#{dossier.to_typed_id}\",
                annotationId: \"#{dossier.champs_private.find { |c| c.type_champ == 'datetime' }.to_typed_id}\",
                instructeurId: \"#{instructeur.to_typed_id}\",
                value: \"#{1.day.from_now.iso8601}\"
              }) {
                annotation {
                  stringValue
                }
                errors {
                  message
                }
              }
            }"
          end

          context "success" do
            it 'should be a success' do
              expect(gql_errors).to eq(nil)

              expect(gql_data).to eq(dossierModifierAnnotationDatetime: {
                annotation: {
                  stringValue: dossier.reload.champs_private.find { |c| c.type_champ == 'datetime' }.to_s
                },
                errors: nil
              })
            end
          end
        end

        describe 'integer_number' do
          let(:query) do
            "mutation {
              dossierModifierAnnotationIntegerNumber(input: {
                dossierId: \"#{dossier.to_typed_id}\",
                annotationId: \"#{dossier.champs_private.find { |c| c.type_champ == 'integer_number' }.to_typed_id}\",
                instructeurId: \"#{instructeur.to_typed_id}\",
                value: 42
              }) {
                annotation {
                  stringValue
                }
                errors {
                  message
                }
              }
            }"
          end

          context "success" do
            it 'should be a success' do
              expect(gql_errors).to eq(nil)

              expect(gql_data).to eq(dossierModifierAnnotationIntegerNumber: {
                annotation: {
                  stringValue: '42'
                },
                errors: nil
              })
            end
          end
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
