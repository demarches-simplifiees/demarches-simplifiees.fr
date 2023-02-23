describe APIGeoService do
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe 'pays' do
    it 'countrie_code' do
      countries = JSON.parse(Rails.root.join('spec/fixtures/files/pays_dump.json').read)
      countries_without_code = countries.map { APIGeoService.country_code(_1) }.count(&:nil?)
      expect(countries_without_code).to eq(67)
    end

    describe 'country_name' do
      it 'Kosovo' do
        expect(APIGeoService.country_code('Kosovo')).to eq('XK')
        expect(APIGeoService.country_name('XK')).to eq('Kosovo')
      end

      it 'Thaïlande' do
        expect(APIGeoService.country_code('Thaïlande')).to eq('TH')
        expect(APIGeoService.country_name('TH')).to eq('Thaïlande')
      end
    end
  end

  describe 'regions', vcr: { cassette_name: 'api_geo_regions' } do
    it 'return sorted results' do
      expect(APIGeoService.regions.size).to eq(18)
      expect(APIGeoService.regions.first).to eq(code: '84', name: 'Auvergne-Rhône-Alpes')
      expect(APIGeoService.regions.last).to eq(code: '93', name: 'Provence-Alpes-Côte d’Azur')
    end
  end

  describe 'departements', vcr: { cassette_name: 'api_geo_departements' } do
    it 'return sorted results' do
      expect(APIGeoService.departements.size).to eq(110)
      expect(APIGeoService.departements.first).to eq(code: '99', name: 'Etranger')
      expect(APIGeoService.departements.second).to eq(code: '01', name: 'Ain')
      expect(APIGeoService.departements.last).to eq(code: '989', name: 'Île de Clipperton')
    end
  end

  describe 'communes', vcr: { cassette_name: 'api_geo_communes' } do
    it 'return sorted results' do
      expect(APIGeoService.communes('01').size).to eq(393)
      expect(APIGeoService.communes('01').first).to eq(code: '01004', name: 'Ambérieu-en-Bugey', postal_codes: ['01500'])
      expect(APIGeoService.communes('01').last).to eq(code: '01457', name: 'Vonnas', postal_codes: ['01540'])
    end
  end

  describe 'commune_name', vcr: { cassette_name: 'api_geo_communes' } do
    subject { APIGeoService.commune_name('01', '01457') }
    it { is_expected.to eq('Vonnas') }
  end

  describe 'commune_code', vcr: { cassette_name: 'api_geo_communes' } do
    subject { APIGeoService.commune_code('01', 'Vonnas') }
    it { is_expected.to eq('01457') }
  end

  describe 'commune_postal_codes', vcr: { cassette_name: 'api_geo_communes' } do
    subject { APIGeoService.commune_postal_codes('01', '01457') }
    it { is_expected.to eq(['01540']) }
  end

  describe 'epcis', vcr: { cassette_name: 'api_geo_epcis' } do
    it 'return sorted results' do
      expect(APIGeoService.epcis('01').size).to eq(17)
      expect(APIGeoService.epcis('01').first).to eq(code: '200042935', name: 'CA Haut - Bugey Agglomération')
    end
  end
end
