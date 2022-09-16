describe Champs::CarteChamp do
  let(:champ) { Champs::CarteChamp.new(geo_areas: geo_areas, type_de_champ: create(:type_de_champ_carte)) }
  let(:value) { '' }
  let(:coordinates) { [[2.3859214782714844, 48.87442541960633], [2.3850631713867183, 48.87273183590832], [2.3809432983398438, 48.87081237174292], [2.3859214782714844, 48.87442541960633]] }
  let(:geo_json) do
    {
      "type" => 'Polygon',
      "coordinates" => coordinates
    }
  end
  let(:legacy_geo_json) do
    {
      type: 'MultiPolygon',
      coordinates: [coordinates]
    }
  end

  describe '#to_feature_collection' do
    subject { champ.to_feature_collection }

    let(:feature_collection) {
      {
        type: 'FeatureCollection',
        id: champ.type_de_champ.stable_id,
        bbox: champ.bounding_box,
        features: features
      }
    }

    context 'when has no geo_areas' do
      let(:geo_areas) { [] }
      let(:features) { [] }

      it { is_expected.to eq(feature_collection) }
    end

    context 'when has one geo_area' do
      let(:geo_areas) { [build(:geo_area, :selection_utilisateur, geometry: geo_json)] }
      let(:features) { geo_areas.map(&:to_feature) }

      it { is_expected.to eq(feature_collection) }
    end
  end

  describe "#for_export" do
    context "when geo areas is a point" do
      let(:geo_areas) { [build(:geo_area, :selection_utilisateur, :point)] }

      it "returns point label" do
        expect(champ.for_export).to eq(["Un point situé à 46°32'19\"N 2°25'42\"E", champ.to_feature_collection.to_json])
      end
    end

    context "when geo area is a cadastre parcelle" do
      let(:geo_areas) { [build(:geo_area, :selection_utilisateur, :cadastre)] }

      it "returns cadastre parcelle label" do
        expect(champ.for_export.first).to match(/Parcelle n° 42/)
      end
    end
  end
end
