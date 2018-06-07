describe Users::RegistrationsController, type: :controller do
  let(:email) { 'test@octo.com' }
  let(:password) { 'password' }

  let(:user) { { email: email, password: password } }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#create' do
    subject do
      post :create, params: { user: user }
    end

    context 'when user is correct' do
      it 'sends confirmation instruction' do
        message = double()
        expect(DeviseUserMailer).to receive(:confirmation_instructions).and_return(message)
        expect(message).to receive(:deliver_later)

        subject
      end
    end

    context 'when user is not correct' do
      let(:user) { { email: '', password: password } }

      it 'not sends confirmation instruction' do
        expect(DeviseUserMailer).not_to receive(:confirmation_instructions)

        subject
      end
    end

    context 'when the user already exists' do
      let!(:existing_user) { create(:user, email: email, password: password) }

      before do
        allow(UserMailer).to receive(:new_account_warning).and_return(double(deliver_later: 'deliver'))
        subject
      end

      it { expect(response).to redirect_to(root_path) }
      it { expect(flash.notice).to eq(I18n.t('devise.registrations.signed_up_but_unconfirmed')) }
      it { expect(UserMailer).to have_received(:new_account_warning) }
    end
  end
end
