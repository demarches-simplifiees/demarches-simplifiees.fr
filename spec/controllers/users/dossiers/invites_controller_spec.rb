describe Users::Dossiers::InvitesController, type: :controller do
  describe '#authenticate_user!' do
    let(:user) { create :user }
    let(:dossier) { create(:dossier, :en_construction) }
    let(:invite) { create(:invite, dossier: dossier) }

    subject { get :show, params: { id: invite.id, email: email } }

    context 'when email is not set' do
      let(:email) { nil }

      context 'and user is not connected' do
        it { is_expected.to redirect_to new_user_session_path }
      end

      context 'and user is connected' do
        let(:invite) { create :invite, dossier: dossier, user: user }
        before { sign_in invite.user }
        it { is_expected.to redirect_to(dossier_path(dossier)) }
      end
    end

    context 'when email is blank' do
      let(:email) { '' }
      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'when email is not blank' do
      context 'when email is affected at an user' do
        let(:email) { user.email }
        it { is_expected.to redirect_to new_user_session_path }
      end

      context 'when email is not affected at an user' do
        let(:email) { 'new_user@octo.com' }
        it { is_expected.to redirect_to new_user_registration_path(user: { email: email }) }
      end
    end
  end

  describe '#GET show' do
    let(:user) { create :user }
    let(:dossier) { create :dossier }
    let(:invite) { create :invite, email: email, dossier: dossier }

    before do
      sign_in user
    end

    subject! { get :show, params: { id: invite.id } }

    context 'when invitation ID is attached at the user email account' do
      let(:email) { user.email }

      context 'and dossier is a brouillon' do
        let(:dossier) { create :dossier, state: Dossier.states.fetch(:brouillon) }
        it { is_expected.to redirect_to brouillon_dossier_path(dossier) }
      end

      context 'and dossier is not a brouillon' do
        let(:dossier) { create :dossier, :en_construction }
        it { is_expected.to redirect_to(dossier_path(dossier)) }
      end
    end

    context 'when invitation ID is not attached at the user email account' do
      let(:email) { 'fake@email.com' }
      it { is_expected.to redirect_to dossiers_path }
      it { expect(flash[:alert]).to be_present }
    end
  end
end
