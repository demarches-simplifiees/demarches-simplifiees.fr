require 'spec_helper'

describe Users::ProfilController, type: :controller do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  before { sign_in(user) }

  describe 'POST #renew_api_token' do
    let(:administrateur) { create(:administrateur) }

    before { sign_in(administrateur) }

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
      let!(:user2) { create(:user) }

      before do
        patch :update_email, params: { user: { email: 'incorrect' } }
        user.reload
      end

      it { expect(response).to redirect_to(profil_path) }
      it { expect(flash.alert).to eq(['Email invalide']) }
    end
  end
end
