require 'spec_helper'

describe AddressController, type: :controller do
  describe '#GET get' do
    subject { get :get, params: { request: request } }

    before do
      subject
    end

    context 'when request return result', vcr: { cassette_name: 'api_adresse_search_paris_2' } do
      let (:request) { 'Paris' }

      it { expect(response.status).to eq 200 }
      it { expect(response.body).to eq '[{"label":"Paris"},{"label":"Paris 63120 Courpière"},{"label":"PARIS (Vaillac) 46240 Cœur de Causse"},{"label":"Paris 40500 Saint-Sever"},{"label":"Paris Buton 37140 Bourgueil"}]' }
    end

    context 'when request return nothing', vcr: { cassette_name: 'api_adresse_search_nothing_2' } do
      let (:request) { 'je recherche pas grand chose' }

      it { expect(response.status).to eq 200 }
      it { expect(response.body).to eq "[]" }
    end
  end

  describe '#GET get_address_point' do
    let(:dossier_id) { "1" }
    subject { get :get_address_point, params: { request: request, dossier_id: dossier_id } }

    before do
      subject
    end

    context 'when request return result', vcr: { cassette_name: 'api_adresse_search_paris' } do
      let(:request) { 'Paris' }

      it { expect(response.body).to eq ({ lon: '2.3469', lat: '48.8589', zoom: '14', dossier_id: dossier_id }).to_json }
    end

    context 'when request return nothing', vcr: { cassette_name: 'api_adresse_search_nothing' } do
      let(:request) { 'je recherche pas grand chose' }

      it { expect(response.body).to eq ({ lon: nil, lat: nil, zoom: '14', dossier_id: dossier_id }).to_json }
    end
  end
end
