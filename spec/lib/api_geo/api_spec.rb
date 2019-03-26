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

  describe '.search_rpg', vcr: { cassette_name: 'api_geo_search_rpg' } do
    let(:coordinates) do
      [
        [
          2.3945903778076176,
          46.53312237252731
        ],
        [
          2.394933700561524,
          46.532590956418076
        ],
        [
          2.3948478698730473,
          46.53170525134736
        ],
        [
          2.393732070922852,
          46.530760483351195
        ],
        [
          2.3909854888916016,
          46.5309376286023
        ],
        [
          2.391414642333985,
          46.531232869403546
        ],
        [
          2.3913288116455083,
          46.53253190986272
        ],
        [
          2.39278793334961,
          46.53329951007484
        ],
        [
          2.3945903778076176,
          46.53312237252731
        ]
      ]
    end

    let(:geo_json) {
      GeojsonService.to_json_polygon_for_rpg(coordinates)
    }

    subject { described_class.search_rpg(geo_json) }

    it { expect(subject[:features].size).to eq 3 }
  end
end
