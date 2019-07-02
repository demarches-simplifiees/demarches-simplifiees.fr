require 'spec_helper'

describe Users::ProfilController, type: :controller do
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
end
