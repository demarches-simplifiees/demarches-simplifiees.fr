# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillDepartementTypeDeChamp, type: :model do
  let(:procedure) { create(:procedure) }
  let(:type_de_champ) { build(:type_de_champ_departements, procedure: procedure) }

  describe 'ancestors' do
    subject { described_class.build(type_de_champ, procedure.active_revision) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#possible_values' do
    let(:expected_values) {
      "Un <a href=\"https://fr.wikipedia.org/wiki/Num%C3%A9rotation_des_d%C3%A9partements_fran%C3%A7ais\" target=\"_blank\">numéro de département</a><br><a title=\"Toutes les valeurs possibles — Nouvel onglet\" target=\"_blank\" rel=\"noopener noreferrer\" href=\"/procedures/#{procedure.path}/prefill_type_de_champs/#{type_de_champ.id}\">Voir toutes les valeurs possibles</a>"
    }
    subject(:possible_values) { described_class.new(type_de_champ, procedure.active_revision).possible_values }

    before { type_de_champ.reload }

    it { expect(possible_values).to match(expected_values) }
  end
end
