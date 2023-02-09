# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillRepetitionTypeDeChamp, type: :model, vcr: { cassette_name: 'api_geo_regions' } do
  let(:procedure) { build(:procedure) }
  let(:type_de_champ) { build(:type_de_champ_repetition, :with_types_de_champ, :with_region_types_de_champ, procedure: procedure) }
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
    let(:expected_value) { ["sub type de champ: Un texte court", "sub type de champ2: Un nombre entier", "region sub_champ: <a title=\"Toutes les valeurs possibles — Nouvel onglet\" target=\"_blank\" rel=\"noopener noreferrer\" href=\"/procedures/#{procedure.path}/prefill_type_de_champs/#{region_repetition.id}\">Voir toutes les valeurs possibles</a>"] }

    it { expect(possible_values).to eq(expected_value) }
  end

  describe '#example_value' do
    subject(:example_value) { described_class.new(type_de_champ).example_value }
    let(:expected_value) { ["{\"sub type de champ\":\"Texte court\", \"sub type de champ2\":\"42\", \"region sub_champ\":\"53\"}", "{\"sub type de champ\":\"Texte court\", \"sub type de champ2\":\"42\", \"region sub_champ\":\"53\"}"] }

    it { expect(example_value).to eq(expected_value) }
  end

  describe '#possible_values_sentence' do
    subject(:possible_values_sentence) { described_class.new(type_de_champ).possible_values_sentence }
    let(:expected_value) { "Un tableau de dictionnaires avec les valeurs possibles pour chaque champ de la répétition.<br>sub type de champ: Un texte court<br>sub type de champ2: Un nombre entier<br>region sub_champ: <a title=\"Toutes les valeurs possibles — Nouvel onglet\" target=\"_blank\" rel=\"noopener noreferrer\" href=\"/procedures/#{procedure.path}/prefill_type_de_champs/#{region_repetition.id}\">Voir toutes les valeurs possibles</a>" }

    it { expect(possible_values_sentence).to eq(expected_value) }
  end
end
