require 'spec_helper'

describe ApiGeo::RPGAdapter do
  subject { described_class.new(coordinates).results }

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

  context 'coordinates are filled', vcr: { cassette_name: 'api_geo_search_rpg' } do
    describe 'Attribut filter' do
      it { expect(subject.size).to eq(3) }
      it do
        expect(subject.first.keys).to eq([
          :culture,
          :code_culture,
          :surface,
          :bio,
          :geometry,
          :geo_reference_id
        ])
      end
    end
  end
end
