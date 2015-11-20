require 'spec_helper'

describe Users::ProcedureController, type: :controller do
  let!(:procedure) { create(:procedure) }

  describe 'GET #index' do
    before do
      get :index, procedure_id: procedure
    end

    context 'when params procedure_id is present' do
      context 'when procedure_id is valid' do
        context 'when user is logged in' do
          before do
            sign_in create(:user)
          end

          subject { get :index, procedure_id: procedure }
          it { expect(subject).to have_http_status(:success) }

          context 'when procedure_id is not valid' do
            let(:procedure) { '' }
            it { is_expected.to have_http_status(404) }
          end
        end
        context 'when user is not logged' do
          it { expect(response).to have_http_status(302) }
        end
      end
    end
  end
end
