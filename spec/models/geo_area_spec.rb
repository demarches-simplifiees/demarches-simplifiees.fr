RSpec.describe GeoArea, type: :model do
  describe '#area' do
    let(:geo_area) { build(:geo_area, :polygon) }

    it { expect(geo_area.area).to eq(103.6) }
  end

  describe '#area (hourglass polygon)' do
    let(:geo_area) { build(:geo_area, :hourglass_polygon) }

    it { expect(geo_area.area).to eq(32.4) }
  end

  describe '#length' do
    let(:geo_area) { build(:geo_area, :line_string) }

    it { expect(geo_area.length).to eq(21.2) }
  end

  describe '#location' do
    let(:geo_area) { build(:geo_area, :point) }

    it { expect(geo_area.location).to eq("46°32'19\"N 2°25'42\"E") }
  end

  describe '#rgeo_geometry' do
    let(:geo_area) { build(:geo_area, :polygon) }
    let(:polygon) do
      {
        "type" => "Polygon",
        "coordinates" => [
          [
            [2.428439855575562, 46.538476837725796],
            [2.4284291267395024, 46.53842148758162],
            [2.4282521009445195, 46.53841410755813],
            [2.42824137210846, 46.53847314771794],
            [2.428284287452698, 46.53847314771794],
            [2.428364753723145, 46.538487907747864],
            [2.4284291267395024, 46.538491597754714],
            [2.428439855575562, 46.538476837725796]
          ]
        ]
      }
    end

    it { expect(geo_area.geometry).to eq(polygon) }

    context 'polygon_with_extra_coordinate' do
      let(:geo_area) { build(:geo_area, :polygon_with_extra_coordinate) }

      it { expect(geo_area.geometry).not_to eq(polygon) }
      it { expect(geo_area.safe_geometry).to eq(polygon) }
    end
  end
end
