# frozen_string_literal: true

describe Users::ActivateController, type: :controller do
  describe '#new' do
    before do
      allow(controller).to receive(:trust_device)
      get :new, params: { token: token }
    end

    context 'when the token is bad' do
      let(:user) { create(:user) }
      let(:token) { 'bad' }
      it { expect(controller).not_to have_received(:trust_device) }
    end
  end

  describe '#create' do
    let!(:instructeur) { create(:instructeur) }
    let!(:user) { instructeur.user }
    let(:token) { user.send(:set_reset_password_token) }
    let(:password) { SECURE_PASSWORD }

    before { post :create, params: { user: { reset_password_token: token, password: password } } }

    context 'when the token is ok' do
      it { expect(user.reload.valid_password?(password)).to be true }
      it { expect(response).to redirect_to(instructeur_procedures_path) }
    end

    context 'when the token is bad' do
      let(:token) { 'bad' }

      it { expect(user.reload.valid_password?(password)).to be false }
      it { expect(response).to redirect_to(users_activate_path(token: token)) }
    end
  end

  describe '#confirm_email' do
    let(:user) { create(:user) }
    let(:dossier) { create(:dossier, user: user) }

    before { user.invite_tiers!(dossier) }

    context 'when the confirmation token is valid' do
      before do
        get :confirm_email, params: { token: user.confirmation_token }
        user.reload
      end

      it 'updates the email_verified_at' do
        expect(user.email_verified_at).to be_present
        expect(user.confirmation_token).to be_present
      end

      it 'redirects to root path with a success notice' do
        expect(response).to redirect_to(root_path(user))
        expect(flash[:notice]).to eq('Votre email a bien été vérifié')
      end
    end

    context 'when the confirmation token is valid but already used' do
      before do
        get :confirm_email, params: { token: user.confirmation_token }
        get :confirm_email, params: { token: user.confirmation_token }
      end

      it 'redirects to root path with an explanation notice' do
        expect(response).to redirect_to(root_path(user))
        expect(flash[:notice]).to eq('Votre email est déjà vérifié')
      end
    end

    context 'when the confirmation token is too old or not valid' do
      subject { get :confirm_email, params: { token: user.confirmation_token } }

      before do
        user.update!(confirmation_sent_at: 3.days.ago)
      end

      it 'redirects to root path with an explanation notice and it send a new link if user present' do
        expect { subject }.to have_enqueued_mail(UserMailer, :invite_tiers)
        expect(response).to redirect_to(root_path(user))
        expect(flash[:alert]).to eq("Ce lien n'est plus valable, un nouveau lien a été envoyé à l'adresse #{user.email}")
      end
    end
  end
end
