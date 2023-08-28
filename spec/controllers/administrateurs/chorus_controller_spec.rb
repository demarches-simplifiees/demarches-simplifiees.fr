describe Administrateurs::ChorusController, type: :controller do
  describe 'edit' do
    let(:user) { create(:user) }
    let(:admin) { create(:administrateur, user: create(:user)) }
    let(:procedure) { create(:procedure, administrateurs: [admin]) }
    subject { get :edit, params: { procedure_id: procedure.id } }

    context 'not signed in' do
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'signed in but not admin of procedure' do
      before { sign_in(user) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'signed as admin' do
      before { sign_in(admin.user) }
      it { is_expected.to have_http_status(200) }
    end
  end
end
