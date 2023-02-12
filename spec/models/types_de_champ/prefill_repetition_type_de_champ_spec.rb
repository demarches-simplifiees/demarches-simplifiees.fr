# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillRepetitionTypeDeChamp, type: :model, vcr: { cassette_name: 'api_geo_regions' } do
  let(:procedure) { build(:procedure) }
  let(:type_de_champ) { build(:type_de_champ_repetition, :with_types_de_champ, :with_region_types_de_champ, procedure: procedure) }
  let(:champ) { create(:champ_repetition, type_de_champ: type_de_champ) }
  let(:prefillable_subchamps) { TypesDeChamp::PrefillRepetitionTypeDeChamp.new(type_de_champ).send(:prefillable_subchamps) }
  let(:region_repetition) { prefillable_subchamps.third }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe 'ancestors' do
    subject { described_class.build(type_de_champ) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#possible_values' do
    subject(:possible_values) { described_class.new(type_de_champ).possible_values }
    let(:expected_value) {
      "Un tableau de dictionnaires avec les valeurs possibles pour chaque champ de la répétition.</br><ul><li>sub type de champ: Un texte court</li><li>sub type de champ2: Un nombre entier</li><li>region sub_champ: Un <a href=\"https://fr.wikipedia.org/wiki/R%C3%A9gion_fran%C3%A7aise\" target=\"_blank\">code INSEE de région</a><br><a title=\"Toutes les valeurs possibles — Nouvel onglet\" target=\"_blank\" rel=\"noopener noreferrer\" href=\"/procedures/#{procedure.path}/prefill_type_de_champs/#{region_repetition.id}\">Voir toutes les valeurs possibles</a></li></ul>"
    }

    it {
      expect(possible_values).to eq(expected_value)
    }
  end

  describe '#example_value' do
    subject(:example_value) { described_class.new(type_de_champ).example_value }
    let(:expected_value) { ["{\"sub type de champ\":\"Texte court\", \"sub type de champ2\":\"42\", \"region sub_champ\":\"53\"}", "{\"sub type de champ\":\"Texte court\", \"sub type de champ2\":\"42\", \"region sub_champ\":\"53\"}"] }

    it { expect(example_value).to eq(expected_value) }
  end

  describe '#to_assignable_attributes' do
    subject(:to_assignable_attributes) { described_class.build(type_de_champ).to_assignable_attributes(champ, value) }
    let(:type_de_champ_child) { champ.rows.first.first.type_de_champ }

    context 'when the value is nil' do
      let(:value) { nil }
      it { is_expected.to match([]) }
    end

    context 'when the value is empty' do
      let(:value) { '' }
      it { is_expected.to match([]) }
    end

    context 'when the value is a string' do
      let(:value) { 'hello' }
      it { is_expected.to match([]) }
    end

    context 'when the value is an array with wrong keys' do
      let(:value) { ["{\"blabla\":\"value\"}", "{\"blabla\":\"value2\"}"] }

      it { is_expected.to match([]) }
    end

    context 'when the value is an array with right keys' do
      let(:value) { ["{\"#{type_de_champ_child.libelle}\":\"value\"}", "{\"#{type_de_champ_child.libelle}\":\"value2\"}"] }

      it { is_expected.to match([[{ id: type_de_champ_child.champ.first.id, value: "value" }], [{ id: type_de_champ_child.champ.second.id, value: "value2" }]]) }
    end
  end
end
