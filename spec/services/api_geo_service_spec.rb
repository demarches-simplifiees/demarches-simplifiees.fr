# frozen_string_literal: true

describe APIGeoService do
  describe 'pays' do
    it 'countrie_code', :slow do
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

  describe 'regions' do
    it 'return sorted results' do
      expect(APIGeoService.regions.size).to eq(18)
      expect(APIGeoService.regions.first).to eq(code: '84', name: 'Auvergne-Rhône-Alpes')
      expect(APIGeoService.regions.last).to eq(code: '93', name: 'Provence-Alpes-Côte d’Azur')
    end
  end

  describe 'departements' do
    it 'return sorted results' do
      expect(APIGeoService.departements.size).to eq(110)
      expect(APIGeoService.departements.first).to eq(code: '01', name: 'Ain', region_code: "84")
      expect(APIGeoService.departements.last).to eq(code: '99', name: 'Etranger')
    end
  end

  describe 'communes' do
    it 'return sorted results' do
      expect(APIGeoService.communes('01').size).to eq(397)
      expect(APIGeoService.communes('01').first).to eq(code: '01004', name: 'Ambérieu-en-Bugey', postal_code: '01500', departement_code: '01', epci_code: '240100883', region_code: "84")
      expect(APIGeoService.communes('01').last).to eq(code: '01457', name: 'Vonnas', postal_code: '01540', departement_code: '01', epci_code: '200070555', region_code: "84")
    end
  end

  describe 'communes_by_postal_code' do
    it 'return results', :slow do
      expect(APIGeoService.communes_by_postal_code('01500').size).to eq(8)
      expect(APIGeoService.communes_by_postal_code('75019').size).to eq(1)
      expect(APIGeoService.communes_by_postal_code('69005').size).to eq(1)
      expect(APIGeoService.communes_by_postal_code('13006').size).to eq(1)
      expect(APIGeoService.communes_by_postal_code('73480').size).to eq(3)
      expect(APIGeoService.communes_by_postal_code('20000').first[:code]).to eq('2A004')
      expect(APIGeoService.communes_by_postal_code('37160').size).to eq(7)
    end
  end

  describe 'commune_name' do
    subject { APIGeoService.commune_name('01', '01457') }
    it { is_expected.to eq('Vonnas') }

    context 'Paris' do
      subject { APIGeoService.commune_name('75', '75056') }
      it { is_expected.to eq('Paris') }
    end

    context 'Lyon' do
      subject { APIGeoService.commune_name('69', '69123') }
      it { is_expected.to eq('Lyon') }
    end

    context 'Marseille' do
      subject { APIGeoService.commune_name('13', '13055') }
      it { is_expected.to eq('Marseille') }
    end
  end

  describe 'commune_code' do
    subject { APIGeoService.commune_code('01', 'Vonnas') }
    it { is_expected.to eq('01457') }
  end

  describe 'epcis' do
    it 'return sorted results' do
      expect(APIGeoService.epcis('01').size).to eq(17)
      expect(APIGeoService.epcis('01').first).to eq(code: '200042935', name: 'CA Haut-Bugey Agglomération')
    end
  end

  describe 'parse_ban_address' do
    let(:features) { JSON.parse(Rails.root.join('spec/fixtures/files/api_address/address.json').read)['features'] }
    let(:feature) { features.first }
    subject { APIGeoService.parse_ban_address(feature) }

    context 'with a valid code insee' do
      it { expect(subject[:city_name]).to eq('Paris') }
    end

    context 'with an invalid code insee' do
      let(:feature) do
        features.first.tap {
          _1['properties']['citycode'] = '0000'
        }
      end

      it { expect(subject[:city_name]).to eq('Paris') }
    end

    context 'without postcode (nouméa…)' do
      let(:feature) do
        features.first.tap { _1["properties"].delete("postcode") }
      end

      it do
        expect(subject[:postal_code]).to eq('')
        expect(subject[:city_name]).to eq('Paris')
      end
    end
  end

  describe 'safely_normalize_city_name' do
    let(:department_code) { '75' }
    let(:city_code) { '75056' }
    let(:fallback) { 'Paris' }

    subject { APIGeoService.safely_normalize_city_name(department_code, city_code, fallback) }

    context 'nominal' do
      it { is_expected.to eq('Paris') }
    end

    context 'without department' do
      let(:department_code) { nil }

      it { is_expected.to eq('Paris') }
    end

    context 'without city_code' do
      let(:city_code) { nil }

      it { is_expected.to eq('Paris') }
    end

    context 'with blank department' do
      let(:department_code) { '' }

      it { is_expected.to eq('Paris') }
    end

    context 'with blank city_code' do
      let(:city_code) { '' }

      it { is_expected.to eq('Paris') }
    end
  end
end
