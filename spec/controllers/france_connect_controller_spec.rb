require 'spec_helper'

describe FranceConnectController, type: :controller do

  describe '.login' do
    it 'redirect to france connect serveur' do
      get :login
      expect(response.status).to eq(302)
    end
  end
end

