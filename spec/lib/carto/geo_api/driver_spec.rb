require 'spec_helper'

describe Carto::GeoAPI::Driver do
  describe '.regions', vcr: { cassette_name: 'geoapi_regions' } do
    subject { described_class.regions }

    it { expect(subject.code).to eq 200 }
  end

  describe '.departements', vcr: { cassette_name: 'geoapi_departements' } do
    subject { described_class.departements }

    it { expect(subject.code).to eq 200 }
  end

  describe '.pays' do
    subject { described_class.pays }

    it { is_expected.to eq File.open('app/lib/carto/geo_api/pays.json').read }
  end
end
