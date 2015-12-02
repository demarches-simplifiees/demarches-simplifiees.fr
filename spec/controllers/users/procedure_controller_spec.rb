require 'spec_helper'

describe Users::ProcedureController, type: :controller do
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }

  describe 'GET #index' do

    subject { get :index, procedure_id: procedure_id }

    context 'when params procedure_id is present' do
      context 'when procedure_id is valid' do
        context 'when user is logged in' do
          before do
            sign_in create(:user)
          end

          it { is_expected.to have_http_status(:success) }

          context 'when procedure is archived' do
            let(:procedure) { create(:procedure, archived: 'true') }

            it { is_expected.to have_http_status(404) }
          end
        end
        context 'when user is not logged' do
          it { is_expected.to have_http_status(302) }
        end
      end

      context 'when procedure_id is not valid' do
        let(:procedure_id) { 0 }

        before do
          sign_in create(:user)
        end

        it { is_expected.to have_http_status(404) }
      end
    end
  end
end
