# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillRegionTypeDeChamp, type: :model do
  let(:procedure) { create(:procedure) }
  let(:type_de_champ) { create(:type_de_champ_regions, procedure: procedure) }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe 'ancestors' do
    subject { described_class.build(type_de_champ) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#possible_values', vcr: { cassette_name: 'api_geo_regions' } do
    let(:expected_values) { "Un <a href=\"https://fr.wikipedia.org/wiki/R%C3%A9gion_fran%C3%A7aise\" target=\"_blank\" rel=\"noopener noreferrer\">code INSEE de région</a><br><a title=\"Toutes les valeurs possibles — Nouvel onglet\" target=\"_blank\" rel=\"noopener noreferrer\" href=\"/procedures/#{procedure.path}/prefill_type_de_champs/#{type_de_champ.id}\">Voir toutes les valeurs possibles</a>" }
    subject(:possible_values) { described_class.new(type_de_champ).possible_values }

    before { type_de_champ.reload }

    it {
      expect(possible_values).to eq(expected_values)
    }
  end
end
