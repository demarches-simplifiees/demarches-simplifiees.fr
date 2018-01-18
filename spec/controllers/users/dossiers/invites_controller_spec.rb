describe Users::Dossiers::InvitesController, type: :controller do
  describe '#authenticate_user!' do
    let(:user) { create :user }
    let(:invite) { create :invite }

    context 'when email is not set' do
      context 'when user is not connected' do
        before do
          get :show, params: { id: invite.id }
        end

        it { is_expected.to redirect_to new_user_session_path }
      end

      context 'when user is connected' do
        let!(:invite) { create :invite, user: user }

        before do
          sign_in invite.user

          get :show, params: { id: invite.id }
        end

        it { expect(response.status).to eq 200 }
      end
    end

    context 'when email is set' do
      before do
        get :show, params: { id: invite.id, email: email }
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

          it { is_expected.to redirect_to new_user_registration_path(user_email: email) }
        end
      end
    end
  end

  describe '#GET show' do
    let(:user) { create :user }

    let(:invite) { create :invite, email: email, dossier: (create :dossier) }

    subject { get :show, params: { id: invite.id } }

    before do
      sign_in user
    end

    context 'when invitation ID is attach at the user email account' do
      let(:email) { user.email }
      it { expect(subject.status).to eq 200 }
    end

    context 'when invitation ID is not attach at the user email account' do
      let(:email) { 'fake@email.com' }

      it { expect(subject.status).to eq 302 }
      it { is_expected.to redirect_to users_dossiers_path }
    end
  end
end
