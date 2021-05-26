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

  describe '#valid?' do
    let(:geo_area) { build(:geo_area, :polygon) }

    context 'polygon' do
      it { expect(geo_area.valid?).to be_truthy }
    end

    context 'hourglass_polygon' do
      let(:geo_area) { build(:geo_area, :hourglass_polygon) }
      it { expect(geo_area.valid?).to be_falsey }
    end

    context 'line_string' do
      let(:geo_area) { build(:geo_area, :line_string) }
      it { expect(geo_area.valid?).to be_truthy }
    end

    context 'point' do
      let(:geo_area) { build(:geo_area, :point) }
      it { expect(geo_area.valid?).to be_truthy }
    end

    context 'invalid_right_hand_rule_polygon' do
      let(:geo_area) { build(:geo_area, :invalid_right_hand_rule_polygon) }
      it { expect(geo_area.valid?).to be_falsey }
    end
  end

  describe "cadastre properties" do
    let(:geo_area) { build(:geo_area, :cadastre) }
    let(:legacy_geo_area) { build(:geo_area, :legacy_cadastre) }

    it "should be backward compatible" do
      expect("#{geo_area.code_dep}#{geo_area.code_com}").to eq(geo_area.commune)
      expect(geo_area.code_arr).to eq(geo_area.prefixe)
      expect(geo_area.surface_parcelle).to eq(geo_area.surface)
    end

    context "(legacy)" do
      it "should be forward compatible" do
        expect("#{legacy_geo_area.code_dep}#{legacy_geo_area.code_com}").to eq(legacy_geo_area.commune)
        expect(legacy_geo_area.code_arr).to eq(legacy_geo_area.prefixe)
        expect(legacy_geo_area.surface_parcelle).to eq(legacy_geo_area.surface)
        expect(legacy_geo_area.cid).to eq(geo_area.cid)
      end
    end
  end

  describe 'description' do
    context 'when properties is nil' do
      let(:geo_area) { build(:geo_area, properties: nil) }

      it { expect(geo_area.description).to be_nil }
    end
  end
end
