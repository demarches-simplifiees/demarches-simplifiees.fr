require 'spec_helper'

describe API::V2::DemarchesController do
  let(:admin) { create(:administrateur) }
  let(:token) { admin.renew_api_token }
  let(:authorization_header) { ActionController::HttpAuthentication::Token.encode_credentials(token) }
  let(:procedure) { create(:procedure, :with_two_type_de_piece_justificative, :with_type_de_champ, :with_type_de_champ_private, administrateur: admin) }

  let(:code) { response.code }
  let(:body) { JSON.parse(response.body, symbolize_names: true) }

  describe 'GET show' do
    let(:response) do
      request.env['HTTP_AUTHORIZATION'] = authorization_header
      get :show, params: { id: demarche_id }
    end

    context 'when demarche is not found' do
      let(:demarche_id) { 99_999_999 }

      it { expect(code).to eq('404') }
    end

    context 'when demarche is found' do
      let(:demarche_id) { procedure.id }

      it { expect(code).to eq('200') }
      it do
        expect(body).to eq({
          data: {
            id: procedure.id.to_s,
            title: procedure.libelle,
            description: procedure.description,
            state: 'BROUILLON',
            created_at: procedure.created_at.iso8601,
            updated_at: procedure.updated_at.iso8601,
            archived_at: nil,
            instructeurs: []
          }
        })
      end
    end
  end
end
