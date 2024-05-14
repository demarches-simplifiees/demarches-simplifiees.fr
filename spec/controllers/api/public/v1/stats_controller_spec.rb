# frozen_string_literal: true

RSpec.describe API::Public::V1::StatsController, type: :controller do
  describe '#index' do
    let(:params) { { id: procedure.id } }
    subject(:index_request) { get :index, params: params }

    shared_examples 'the procedure is found' do
      before do
        create(:dossier, :en_instruction, procedure: procedure)
        create(:dossier, :accepte, procedure: procedure)

        index_request
      end

      it { expect(response).to be_successful }

      it {
        expect(response.parsed_body).to match({
          funnel: procedure.stats_dossiers_funnel.as_json,
          processed: procedure.stats_termines_states.as_json,
          processed_by_week: procedure.stats_termines_by_week.as_json,
          processing_time: procedure.stats_usual_traitement_time.as_json,
          processing_time_by_month: procedure.stats_usual_traitement_time_by_month_in_days.as_json
        }.with_indifferent_access)
      }
    end

    shared_examples 'the procedure is not found' do
      before { index_request }

      it { expect(response).to have_http_status(:not_found) }

      it { expect(response).to have_failed_with("procedure #{procedure.id} is not found") }
    end

    context 'when the procedure is found' do
      context 'when the procedure is publiee' do
        context 'when the procedure is opendata' do
          it_behaves_like 'the procedure is found' do
            let(:procedure) { create(:procedure, :published, opendata: true) }
          end
        end

        context 'when the procedure is not opendata' do
          it_behaves_like 'the procedure is not found' do
            let(:procedure) { create(:procedure, :published, opendata: false) }
          end
        end
      end

      context 'when the procedure is brouillon' do
        context 'when the procedure is opendata' do
          it_behaves_like 'the procedure is found' do
            let(:procedure) { create(:procedure, :draft, opendata: true) }
          end
        end

        context 'when the procedure is not opendata' do
          it_behaves_like 'the procedure is not found' do
            let(:procedure) { create(:procedure, :draft, opendata: false) }
          end
        end
      end

      context 'when the procedure is not publiee and not brouillon' do
        it_behaves_like 'the procedure is found' do
          let(:procedure) { create(:procedure, :closed) }
        end
      end
    end

    context 'when the procedure is not found' do
      it_behaves_like 'the procedure is not found' do
        let(:procedure) { double(Procedure, id: -1) }
      end
    end
  end
end
