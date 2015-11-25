require 'spec_helper'

describe GeojsonService do
  describe '.toGeoJsonPolygon' do

    let(:to_polygon_return) {
      {
          geo: {
              type: "Polygon",
              coordinates: [coordinates]
          }
      }.to_json
    }

    subject { described_class.to_json_polygon coordinates }

    describe 'coordinates are empty' do
      let(:coordinates) { '' }

      it { expect(subject).to eq(to_polygon_return) }
    end

    describe 'coordinates are informed' do
      let(:coordinates) {
        [
            [5.93536376953125,
             48.91888968903368],
            [5.93536376953125,
             49.26780455063753],
            [7.094421386718749,
             49.26780455063753],
            [7.094421386718749,
             48.91888968903368],
            [5.93536376953125,
             48.91888968903368]
        ]
      }

      it { expect(subject).to eq(to_polygon_return) }
    end
  end
end
