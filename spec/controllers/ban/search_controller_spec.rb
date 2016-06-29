require 'spec_helper'

describe Ban::SearchController, type: :controller do
  describe '#GET' do

    let (:request) { '' }

    before do
      stub_request(:get, "http://api-adresse.data.gouv.fr/search?limit=5&q=").
          to_return(:status => 200, :body => 'Missing query', :headers => {})
      get :get, request: request
    end

    it { expect(response.status).to eq 200 }
  end
end
