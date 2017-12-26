require 'spec_helper'

describe Admin::ProfileController, type: :controller do
  it { expect(described_class).to be < AdminController }
  let(:administrateur) { create(:administrateur) }

  before { sign_in(administrateur) }

  describe 'POST #renew_api_token' do
    subject { post :renew_api_token }

    it { expect{ subject }.to change{ administrateur.reload.api_token } }

    it { subject; expect(response.status).to redirect_to(admin_profile_path) }
  end
end
