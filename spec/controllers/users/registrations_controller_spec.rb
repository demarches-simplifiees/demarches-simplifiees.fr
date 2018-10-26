describe Users::RegistrationsController, type: :controller do
  let(:email) { 'test@octo.com' }
  let(:password) { 'password' }

  let(:user) { { email: email, password: password } }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#new' do
    subject! { get :new }

    it { expect(response).to have_http_status(:ok) }
    it { expect(response).to render_template(:new) }

    context 'when an email address is provided' do
      render_views true
      subject! { get :new, params: { user: { email: 'test@exemple.fr' } } }

      it 'prefills the form with the email address' do
        expect(response.body).to include('test@exemple.fr')
      end
    end
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
      let!(:existing_user) { create(:user, email: email, password: password, confirmed_at: confirmed_at) }

      before do
        allow(UserMailer).to receive(:new_account_warning).and_return(double(deliver_later: 'deliver'))
      end

      context 'and the user is confirmed' do
        let(:confirmed_at) { Time.zone.now }

        before { subject }

        it { expect(response).to redirect_to(root_path) }
        it { expect(flash.notice).to eq(I18n.t('devise.registrations.signed_up_but_unconfirmed')) }
        it { expect(UserMailer).to have_received(:new_account_warning) }
      end

      context 'and the user is not confirmed' do
        let(:confirmed_at) { nil }

        before do
          expect_any_instance_of(User).to receive(:resend_confirmation_instructions)
          subject
        end

        it { expect(response).to redirect_to(root_path) }
        it { expect(flash.notice).to eq(I18n.t('devise.registrations.signed_up_but_unconfirmed')) }
        it { expect(UserMailer).not_to have_received(:new_account_warning) }
      end
    end
  end
end
