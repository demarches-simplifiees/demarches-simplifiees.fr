require 'spec_helper'

describe API::V2::DossiersController do
  let(:admin) { create(:administrateur) }
  let(:token) { admin.renew_api_token }
  let(:authorization_header) { ActionController::HttpAuthentication::Token.encode_credentials(token) }
  let(:procedure) { create(:procedure, :with_two_type_de_piece_justificative, :with_type_de_champ, :with_type_de_champ_private, administrateur: admin) }
  let!(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

  let(:code) { response.code }
  let(:body) { JSON.parse(response.body, symbolize_names: true) }

  describe 'GET show' do
    let(:response) do
      request.env['HTTP_AUTHORIZATION'] = authorization_header
      get :show, params: { id: dossier_id }
    end

    context 'when dossier is not found' do
      let(:dossier_id) { 99_999_999 }

      it { expect(code).to eq('404') }
    end

    context 'when dossier is found' do
      let(:dossier_id) { dossier.id }

      it { expect(code).to eq('200') }
      it do
        expect(body).to eq({
          data: {
            id: dossier.id.to_s,
            state: 'EN_CONSTRUCTION',
            usager: {
              id: dossier.user.to_typed_id,
              email: dossier.user.email
            },
            instructeurs: [],
            created_at: dossier.created_at.iso8601,
            updated_at: dossier.updated_at.iso8601
          }
        })
      end
    end
  end

  describe 'GET index' do
    let(:response) do
      request.env['HTTP_AUTHORIZATION'] = authorization_header
      get :index, params: { demarche_id: demarche_id }
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
          data: [
            {
              id: dossier.id.to_s,
              state: 'EN_CONSTRUCTION',
              usager: {
                id: dossier.user.to_typed_id,
                email: dossier.user.email
              },
              instructeurs: [],
              created_at: dossier.created_at.iso8601,
              updated_at: dossier.updated_at.iso8601
            }
          ],
          meta: {
            end_cursor: "MQ==",
            has_next_page: false,
            has_previous_page: false,
            start_cursor: "MQ=="
          }
        })
      end
    end
  end
      end
    end
  end
end
