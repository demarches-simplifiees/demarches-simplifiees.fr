require 'spec_helper'

describe API::V2::DossiersController do
  let(:admin) { create(:administrateur) }
  let(:token) { admin.renew_api_token }
  let(:authorization_header) { ActionController::HttpAuthentication::Token.encode_credentials(token) }
  let(:procedure) { create(:procedure, :with_two_type_de_piece_justificative, :with_type_de_champ, :with_type_de_champ_private, administrateur: admin) }
  let!(:dossier) { create(:dossier, :en_construction, created_at: 1.hour.ago, procedure: procedure) }

  let(:code) { response.code }
  let(:body) { JSON.parse(response.body, symbolize_names: true) }

  describe 'GET show' do
    let(:dossier_id) { dossier.id }
    let(:response) do
      request.env['HTTP_AUTHORIZATION'] = authorization_header
      get :show, params: { id: dossier_id }
    end

    context 'when dossier is unauthorized' do
      let(:authorization_header) { nil }

      it { expect(code).to eq('401') }
    end

    context 'when dossier is not found' do
      let(:dossier_id) { 99_999_999 }

      it { expect(code).to eq('404') }
    end

    context 'when dossier is found' do
      it do
        expect(code).to eq('200')
        expect(body).to eq({
          dossier: {
            id: dossier.id.to_s,
            state: Dossier.states.fetch(:en_construction),
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
    let(:demarche_id) { procedure.id }
    let(:params) { { demarche_id: demarche_id } }
    let(:response) do
      request.env['HTTP_AUTHORIZATION'] = authorization_header
      get :index, params: params
    end

    context 'when dossier is unauthorized' do
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
          dossiers: [
            {
              id: dossier.id.to_s,
              state: Dossier.states.fetch(:en_construction),
              usager: {
                id: dossier.user.to_typed_id,
                email: dossier.user.email
              },
              instructeurs: [],
              created_at: dossier.created_at.iso8601,
              updated_at: dossier.updated_at.iso8601
            }
          ],
          pagination: {
            end_cursor: "MQ==",
            has_next_page: false
          }
        })
      end
    end

    context "filter dossiers" do
      context 'when all dossiers created now' do
        before do
          create(:dossier, :en_construction, procedure: procedure)
        end

        context "with ids" do
          let(:params) { { demarche_id: demarche_id, ids: [dossier.id] } }

          it do
            expect(code).to eq('200')
            expect(body[:dossiers].size).to eq(1)
          end
        end

        context "with ids (not found)" do
          let(:params) { { demarche_id: demarche_id, ids: [99_999_999] } }

          it do
            expect(code).to eq('200')
            expect(body[:dossiers].size).to eq(0)
          end
        end

        context "with since" do
          let(:params) { { demarche_id: demarche_id, since: dossier.en_construction_at.iso8601 } }

          it do
            expect(code).to eq('200')
            expect(body[:dossiers].size).to eq(2)
          end
        end
      end

      context "when one dossier in the past" do
        before do
          Timecop.freeze(4.days.ago) { create(:dossier, :en_construction, procedure: procedure) }
        end

        context "with since (and old dossier)" do
          let(:params) { { demarche_id: demarche_id, since: dossier.en_construction_at.iso8601 } }

          it do
            expect(code).to eq('200')
            expect(body[:dossiers].size).to eq(1)
          end
        end
      end
    end
  end
end
