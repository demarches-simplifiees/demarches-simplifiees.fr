require 'spec_helper'

describe APIGeo::API do
  describe '.nationalites', vcr: { cassette_name: 'api_geo_nationalites' } do
    subject { described_class.nationalites }
    let(:nationalites) {
      JSON.parse(File.open('app/lib/api_geo/nationalites.json').read, symbolize_names: true)
    }

    it { is_expected.to eq nationalites }
  end

  describe '.polynesian_cities', vcr: { cassette_name: 'api_geo_polynesian_cities' } do
    subject { described_class.polynesian_cities }
    it { expect(subject.size).to eq(256) }
  end

  describe '.pays' do
    subject { described_class.pays }
    let(:pays) {
      JSON.parse(File.open('app/lib/api_geo/pays.json').read, symbolize_names: true)
    }
    it { is_expected.to eq pays }
  end

  describe '.pays : first elts must be PF, France' do
    subject { described_class.pays[0..1].pluck(:nom) }
    let(:first) { ["POLYNESIE FRANCAISE", "FRANCE"] }

    it { is_expected.to eq first }
  end
end
