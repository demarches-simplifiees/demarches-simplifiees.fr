require 'spec_helper'

describe API::V2::DemarchesController do
  let(:admin) { create(:administrateur) }
  let(:token) { admin.renew_api_token }
  let(:authorization_header) { ActionController::HttpAuthentication::Token.encode_credentials(token) }
  let(:procedure) { create(:procedure, :with_two_type_de_piece_justificative, :with_type_de_champ, :with_type_de_champ_private, administrateur: admin) }

  let(:code) { response.code }
  let(:body) { JSON.parse(response.body, symbolize_names: true) }

  describe 'GET show' do
    let(:demarche_id) { procedure.id }
    let(:response) do
      request.env['HTTP_AUTHORIZATION'] = authorization_header
      get :show, params: { id: demarche_id }
    end

    context 'when demarche is unauthorized' do
      let(:authorization_header) { nil }

      it { expect(code).to eq('401') }
    end

    context 'when demarche is not found' do
      let(:demarche_id) { 99_999_999 }

      it { expect(code).to eq('404') }
    end

    context 'when demarche is found' do
      it do
        expect(code).to eq('200')
        expect(body).to eq({
          demarche: {
            id: procedure.id.to_s,
            title: procedure.libelle,
            description: procedure.description,
            state: 'brouillon',
            created_at: procedure.created_at.iso8601,
            updated_at: procedure.updated_at.iso8601,
            archived_at: nil
          }
        })
      end
    end
  end

  describe "GET instructeurs" do
    let(:demarche_id) { procedure.id }
    let(:gestionnaire) { create(:gestionnaire) }
    let(:response) do
      procedure.gestionnaires << gestionnaire
      request.env['HTTP_AUTHORIZATION'] = authorization_header
      get :instructeurs, params: { id: demarche_id }
    end

    context 'when demarche is unauthorized' do
      let(:authorization_header) { nil }

      it { expect(code).to eq('401') }
    end

    context 'when demarche is not found' do
      let(:demarche_id) { 99_999_999 }

      it { expect(code).to eq('404') }
    end

    context 'when demarche is found' do
      it do
        expect(code).to eq('200')
        expect(body).to eq({
          instructeurs: [
            {
              id: gestionnaire.to_typed_id,
              email: gestionnaire.email
            }
          ]
        })
      end
    end
  end
end
