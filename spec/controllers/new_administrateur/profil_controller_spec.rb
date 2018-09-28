require 'spec_helper'

describe NewAdministrateur::ProfilController, type: :controller do
  let(:administrateur) { create(:administrateur) }

  before { sign_in(administrateur) }

  describe 'POST #renew_api_token' do
    before do
      allow(administrateur).to receive(:renew_api_token)
      allow(controller).to receive(:current_administrateur) { administrateur }
      post :renew_api_token
    end

    it { expect(administrateur).to have_received(:renew_api_token) }
    it { expect(response.status).to render_template(:show) }
    it { expect(flash.notice).to eq('Votre jeton a été regénéré.') }
  end
end
