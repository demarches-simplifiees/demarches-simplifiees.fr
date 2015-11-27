require 'spec_helper'

describe Users::SiretController, type: :controller do
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

          it { expect(subject).to redirect_to(users_path(procedure_id: procedure.id)) }

          context 'when params siret is present' do
            subject { get :index, procedure_id: procedure, siret: '123456789' }

            it { expect(subject).to redirect_to(users_path(procedure_id: procedure.id, siret: '123456789')) }
          end

          context 'when procedure_id is not valid' do
            let(:procedure) { '' }
            it { is_expected.to have_http_status(302) }
          end
          context 'when params procedure_id is not present' do
            subject { get :index }
            it { is_expected.to redirect_to new_user_session_path }
          end
        end
        context 'when user is not logged' do
          it { expect(response).to have_http_status(302) }
        end
      end
    end
  end
end
