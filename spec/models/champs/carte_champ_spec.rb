require 'spec_helper'

describe Champs::CarteChamp do
  let(:champ) { Champs::CarteChamp.new(value: value) }
  let(:value) { '' }
  let(:geo_json) { GeojsonService.to_json_polygon_for_selection_utilisateur(coordinates) }
  let(:coordinates) { [[{ "lat" => 48.87442541960633, "lng" => 2.3859214782714844 }, { "lat" => 48.87273183590832, "lng" => 2.3850631713867183 }, { "lat" => 48.87081237174292, "lng" => 2.3809432983398438 }, { "lat" => 48.8712640169951, "lng" => 2.377510070800781 }, { "lat" => 48.87510283703279, "lng" => 2.3778533935546875 }, { "lat" => 48.87544154230615, "lng" => 2.382831573486328 }, { "lat" => 48.87442541960633, "lng" => 2.3859214782714844 }]] }
  let(:parsed_geo_json) { JSON.parse(geo_json) }

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

    context 'when the value is nil' do
      let(:value) { nil }

      let(:selection) { nil }

      it { is_expected.to eq(render_data) }
    end

    context 'when the value is blank' do
      let(:value) { '' }

      let(:selection) { nil }

      it { is_expected.to eq(render_data) }
    end

    context 'when the value is empty array' do
      let(:value) { '[]' }

      let(:selection) { nil }

      it { is_expected.to eq(render_data) }
    end

    context 'when the value is coordinates' do
      let(:value) { coordinates.to_json }

      let(:selection) { parsed_geo_json }

      it { is_expected.to eq(render_data) }
    end

    context 'when the value is geojson' do
      let(:value) { geo_json }

      let(:selection) { parsed_geo_json }

      it { is_expected.to eq(render_data) }
    end
  end
end
