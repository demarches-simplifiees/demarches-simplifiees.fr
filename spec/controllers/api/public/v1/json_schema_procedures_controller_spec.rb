RSpec.describe API::Public::V1::JSONSchemaProceduresController, type: :controller do
  include Rails.application.routes.url_helpers

  describe '#show' do
    # curl --request POST 'http://localhost:3000/preremplir/:path/schema'

    let(:procedure) { create(:procedure, :published, :with_type_de_champ) }
    subject(:show_request) do
      get :show, params: params
    end

    context 'the procedure is found' do
      let(:params) { { path: procedure.path } }
      let(:expected_response) do
        API::V2::Schema.execute(API::V2::StoredQuery.get('ds-query-v2'),
          variables: {
            demarche: { "number": procedure.id },
            includeRevision: true
          },
          operation_name: "getDemarcheDescriptor")
          .to_h.dig("data", "demarcheDescriptor").to_json
      end

      before { show_request }

      it { expect(response).to have_http_status(:success) }

      it { expect(response.body).to eq(expected_response) }
    end

    context "the procedure is not found" do
      let(:params) { { path: "error" } }

      before { show_request }

      it { expect(response).to have_http_status(:not_found) }

      it { expect(response).to have_failed_with("procedure error is not found") }
    end
  end

  private

  def find_champ_by_stable_id(dossier, stable_id)
    dossier.champs_public.joins(:type_de_champ).find_by(types_de_champ: { stable_id: stable_id })
  end
end
