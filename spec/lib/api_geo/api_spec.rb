require 'spec_helper'

describe ApiGeo::API do
  describe '.regions', vcr: { cassette_name: 'api_geo_regions' } do
    subject { described_class.regions }

    it { expect(subject.size).to eq 18 }
  end

  describe '.departements', vcr: { cassette_name: 'api_geo_departements' } do
    subject { described_class.departements }

    it { expect(subject.size).to eq 101 }
  end

  describe '.pays' do
    subject { described_class.pays }
    let(:pays) {
      JSON.parse(File.open('app/lib/api_geo/pays.json').read, symbolize_names: true)
    }

    it { is_expected.to eq pays }
  end
end
