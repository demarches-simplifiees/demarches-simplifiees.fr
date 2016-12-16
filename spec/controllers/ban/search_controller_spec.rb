require 'spec_helper'

describe Ban::SearchController, type: :controller do
  describe '#GET get' do
    let (:request) { '' }

    before do
      stub_request(:get, "http://api-adresse.data.gouv.fr/search?limit=5&q=").
          to_return(:status => 200, :body => 'Missing query', :headers => {})

      get :get, params: {request: request}
    end

    it { expect(response.status).to eq 200 }
  end

  describe '#GET get_address_point' do
    let(:dossier_id) { "1" }
    subject { get :get_address_point, params: {request: request, dossier_id: dossier_id} }

    before do
      subject
    end

    context 'when request return result', vcr: {cassette_name: 'ban_search_paris'} do
      let(:request) { 'Paris' }

      it { expect(response.body).to eq ({lon: '2.3469', lat: '48.8589', zoom: '14', dossier_id: dossier_id}).to_json }
    end

    context 'when request return nothing', vcr: {cassette_name: 'ban_search_nothing'} do
      let(:request) { 'je recherche pas grand chose' }

      it { expect(response.body).to eq ({lon: nil, lat: nil, zoom: '14', dossier_id: dossier_id}).to_json }
    end
  end
end
