describe Users::ProfilController, type: :controller do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  before { sign_in(user) }

  describe 'GET #show' do
    render_views

    before { post :show }

    context 'when the current user is not an instructeur' do
      it { expect(response.body).to include(I18n.t('users.profil.show.transfer_title')) }

      context 'when an existing transfer exists' do
        let(:dossiers) { Array.new(3) { create(:dossier, user: user) } }
        let(:next_owner) { 'loulou@lou.com' }
        let!(:transfer) { DossierTransfer.initiate(next_owner, dossiers) }

        before { post :show }

        it { expect(response.body).to include(I18n.t('users.profil.show.one_waiting_transfer', count: dossiers.count, email: next_owner)) }
      end
    end

    context 'when the current user is an instructeur' do
      let(:user) { create(:instructeur).user }

      it { expect(response.body).not_to include(I18n.t('users.profil.show.transfer_title')) }
    end
  end

  describe 'POST #renew_api_token' do
    let(:administrateur) { create(:administrateur) }

    before { sign_in(administrateur.user) }

    before do
      allow(administrateur).to receive(:renew_api_token)
      allow(controller).to receive(:current_administrateur) { administrateur }
      post :renew_api_token
    end

    it { expect(administrateur).to have_received(:renew_api_token) }
    it { expect(response.status).to render_template(:show) }
    it { expect(flash.notice).to eq('Votre jeton a été regénéré.') }
  end

  describe 'PATCH #update_email' do
    context 'when everything is fine' do
      before do
        patch :update_email, params: { user: { email: 'loulou@lou.com' } }
        user.reload
      end

      it { expect(user.unconfirmed_email).to eq('loulou@lou.com') }
      it { expect(response).to redirect_to(profil_path) }
      it { expect(flash.notice).to eq(I18n.t('devise.registrations.update_needs_confirmation')) }
    end

    context 'when the mail is already taken' do
      let(:existing_user) { create(:user) }

      before do
        perform_enqueued_jobs do
          patch :update_email, params: { user: { email: existing_user.email } }
        end
        user.reload
      end

      it { expect(user.unconfirmed_email).to be_nil }
      it { expect(ActionMailer::Base.deliveries.last.to).to eq([existing_user.email]) }
      it { expect(response).to redirect_to(profil_path) }
      it { expect(flash.notice).to eq(I18n.t('devise.registrations.update_needs_confirmation')) }
    end

    context 'when the mail is incorrect' do
      before do
        patch :update_email, params: { user: { email: 'incorrect' } }
        user.reload
      end

      it { expect(response).to redirect_to(profil_path) }
      it { expect(flash.alert).to eq(['Courriel invalide']) }
    end

    context 'when the user has an instructeur role' do
      let(:instructeur_email) { 'instructeur_email@a.com' }
      let!(:user) { create(:instructeur, email: instructeur_email).user }

      before do
        patch :update_email, params: { user: { email: requested_email } }
        user.reload
      end

      context 'when the requested email is allowed' do
        let(:requested_email) { 'legit@gouv.fr' }

        it { expect(user.unconfirmed_email).to eq('legit@gouv.fr') }
        it { expect(response).to redirect_to(profil_path) }
        it { expect(flash.notice).to eq(I18n.t('devise.registrations.update_needs_confirmation')) }
      end

      context 'when the requested email is not allowed' do
        let(:requested_email) { 'weird@gmail.com' }

        it { expect(response).to redirect_to(profil_path) }
        it { expect(flash.alert).to include('contactez le support') }
      end
    end
  end

  context 'POST #transfer_all_dossiers' do
    let!(:dossiers) { Array.new(3) { create(:dossier, user: user) } }
    let(:next_owner) { 'loulou@lou.com' }
    let(:created_transfer) { DossierTransfer.first }

    before do
      post :transfer_all_dossiers, params: { next_owner: next_owner }
    end

    it "transfer all dossiers" do
      expect(created_transfer.email).to eq(next_owner)
      expect(created_transfer.dossiers).to match_array(dossiers)
      expect(flash.notice).to eq("Le transfert de 3 dossiers à #{next_owner} est en cours")
    end
  end
end
