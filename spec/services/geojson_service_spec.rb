# frozen_string_literal: true

describe GeojsonService do
  let(:good_coordinates) {
    [
      [5.93536376953125, 48.91888968903368],
      [5.93536376953125, 49.26780455063753],
      [7.094421386718749, 49.26780455063753],
      [7.094421386718749, 48.91888968903368],
      [5.93536376953125, 48.91888968903368]
    ]
  }

  describe '.toGeoJsonPolygonForCadastre' do
    subject { JSON.parse(described_class.to_json_polygon_for_cadastre coordinates) }

    describe 'coordinates are empty' do
      let(:coordinates) { '' }

      it { expect(subject['geom']['type']).to eq('Feature') }
      it { expect(subject['geom']['geometry']['type']).to eq('Polygon') }
      it { expect(subject['geom']['geometry']['coordinates']).to eq([coordinates]) }
    end

    describe 'coordinates are informed' do
      let(:coordinates) { good_coordinates }

      it { expect(subject['geom']['type']).to eq('Feature') }
      it { expect(subject['geom']['geometry']['type']).to eq('Polygon') }
      it { expect(subject['geom']['geometry']['coordinates']).to eq([coordinates]) }
    end
  end
end
