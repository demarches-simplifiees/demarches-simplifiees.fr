describe Champs::CarteChamp do
  let(:champ) { Champs::CarteChamp.new(geo_areas: geo_areas) }
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

  describe '#to_render_data' do
    subject { champ.to_render_data }

    let(:render_data) {
      {
        position: champ.position,
        selection: selection,
        cadastres: [],
        parcellesAgricoles: [],
        quartiersPrioritaires: []
      }
    }

    context 'when has no geo_areas' do
      let(:geo_areas) { [] }
      let(:selection) { nil }

      it { is_expected.to eq(render_data) }
    end

    context 'when has one geo_area' do
      let(:geo_areas) { [build(:geo_area, :selection_utilisateur, geometry: geo_json)] }
      let(:selection) { legacy_geo_json }

      it { is_expected.to eq(render_data) }
    end
  end

  describe '#to_feature_collection' do
    subject { champ.to_feature_collection }

    let(:feature_collection) {
      {
        type: 'FeatureCollection',
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
end
