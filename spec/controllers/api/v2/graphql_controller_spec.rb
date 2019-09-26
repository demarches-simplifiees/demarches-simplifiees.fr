require 'spec_helper'

describe API::V2::GraphqlController do
  let(:admin) { create(:administrateur) }
  let(:token) { admin.renew_api_token }
  let(:procedure) { create(:procedure, :with_all_champs, administrateurs: [admin]) }
  let(:dossier) do
    dossier = create(:dossier,
      :en_construction,
      :with_all_champs,
      procedure: procedure)
    create(:commentaire, dossier: dossier, email: 'test@test.com')
    dossier
  end

  let(:query) do
    "{
      demarche(number: #{procedure.id}) {
        id
        number
        title
        description
        state
        createdAt
        updatedAt
        archivedAt
        groupeInstructeurs {
          label
          instructeurs {
            email
          }
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

    it "should return demarche" do
      expect(gql_errors).to eq(nil)
      expect(gql_data).to eq(demarche: {
        id: procedure.to_typed_id,
        number: procedure.id.to_s,
        title: procedure.libelle,
        description: procedure.description,
        state: 'brouillon',
        archivedAt: nil,
        createdAt: procedure.created_at.iso8601,
        updatedAt: procedure.updated_at.iso8601,
        groupeInstructeurs: [{ instructeurs: [], label: "défaut" }],
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
          nodes: []
        }
      })
    end

    context "dossier" do
      let(:query) do
        "{
          dossier(number: #{dossier.id}) {
            id
            number
            state
            updatedAt
            datePassageEnConstruction
            datePassageEnInstruction
            dateTraitement
            motivation
            motivationAttachmentUrl
            usager {
              id
              email
            }
            instructeurs {
              id
              email
            }
            messages {
              email
              body
              attachmentUrl
            }
            avis {
              email
              question
              answer
              attachmentUrl
            }
            champs {
              id
              label
              stringValue
            }
          }
        }"
      end

      it "should return dossier" do
        expect(gql_errors).to eq(nil)
        expect(gql_data).to eq(dossier: {
          id: dossier.to_typed_id,
          number: dossier.id.to_s,
          state: 'en_construction',
          updatedAt: dossier.updated_at.iso8601,
          datePassageEnConstruction: dossier.en_construction_at.iso8601,
          datePassageEnInstruction: nil,
          dateTraitement: nil,
          motivation: nil,
          motivationAttachmentUrl: nil,
          usager: {
            id: dossier.user.to_typed_id,
            email: dossier.user.email
          },
          instructeurs: [],
          messages: dossier.commentaires.map do |commentaire|
            {
              body: commentaire.body,
              attachmentUrl: nil,
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
  end
end
