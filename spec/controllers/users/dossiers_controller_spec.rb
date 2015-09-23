require 'spec_helper'

describe Users::DossiersController, type: :controller do
  describe '.index' do
    subject { get :index }
    context 'when user is not logged in' do
      it { is_expected.to redirect_to('/users/sign_in') }
    end
    context 'when user is logged in' do
      before do
        sign_in create(:user)
      end
      it { is_expected.to render_template('users/dossiers/index') }
      it { is_expected.to have_http_status(:success) }
    end
  end
end