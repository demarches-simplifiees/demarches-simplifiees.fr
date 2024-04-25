# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillRepetitionTypeDeChamp, type: :model do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, children: [{}, { type: :integer_number }, { type: :regions }] }]) }
  let(:dossier) { create(:dossier, procedure: procedure) }
  let(:type_de_champ) { champ.type_de_champ }
  let(:champ) { dossier.champs.first }
  let(:prefillable_subchamps) { TypesDeChamp::PrefillRepetitionTypeDeChamp.new(type_de_champ, procedure.active_revision).send(:prefillable_subchamps) }
  let(:text_repetition) { prefillable_subchamps.first }
  let(:integer_repetition) { prefillable_subchamps.second }
  let(:region_repetition) { prefillable_subchamps.third }

  describe 'ancestors' do
    subject { described_class.build(type_de_champ, procedure.active_revision) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#possible_values' do
    subject(:possible_values) { described_class.new(type_de_champ, procedure.active_revision).possible_values }
    let(:expected_value) {
      "Un tableau de dictionnaires avec les valeurs possibles pour chaque champ de la répétition.</br><ul><li>champ_#{text_repetition.to_typed_id_for_query}: Un texte court<br></li><li>champ_#{integer_repetition.to_typed_id_for_query}: Un nombre entier<br></li><li>champ_#{region_repetition.to_typed_id_for_query}: Un <a href=\"https://fr.wikipedia.org/wiki/R%C3%A9gion_fran%C3%A7aise\" target=\"_blank\" rel=\"noopener noreferrer\">code INSEE de région</a><br><a title=\"Toutes les valeurs possibles — Nouvel onglet\" target=\"_blank\" rel=\"noopener noreferrer\" href=\"/procedures/#{procedure.path}/prefill_type_de_champs/#{region_repetition.id}\">Voir toutes les valeurs possibles</a></li></ul>"
    }

    it {
      expect(possible_values).to eq(expected_value)
    }
  end

  describe '#example_value' do
    subject(:example_value) { described_class.new(type_de_champ, procedure.active_revision).example_value }
    let(:expected_value) { [{ "champ_#{text_repetition.to_typed_id_for_query}" => "Texte court", "champ_#{integer_repetition.to_typed_id_for_query}" => "42", "champ_#{region_repetition.to_typed_id_for_query}" => "53" }, { "champ_#{text_repetition.to_typed_id_for_query}" => "Texte court", "champ_#{integer_repetition.to_typed_id_for_query}" => "42", "champ_#{region_repetition.to_typed_id_for_query}" => "53" }] }

    it { expect(example_value).to eq(expected_value) }
  end

  describe '#to_assignable_attributes' do
    subject(:to_assignable_attributes) { described_class.build(type_de_champ, procedure.active_revision).to_assignable_attributes(champ, value) }

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

    context 'when the value is an array with some wrong keys' do
      let(:value) { [{ "champ_#{text_repetition.to_typed_id_for_query}" => "value", "blabla" => "value2" }, { "champ_#{integer_repetition.to_typed_id_for_query}" => "value3" }, { "blabla" => "false" }] }

      it { is_expected.to match([[{ id: text_repetition.champ.first.id, value: "value" }], [{ id: integer_repetition.champ.second.id, value: "value3" }]]) }
    end

    context 'when the value is an array with right keys' do
      let(:value) { [{ "champ_#{text_repetition.to_typed_id_for_query}" => "value" }, { "champ_#{text_repetition.to_typed_id_for_query}" => "value2" }] }

      it { is_expected.to match([[{ id: text_repetition.champ.first.id, value: "value" }], [{ id: text_repetition.champ.second.id, value: "value2" }]]) }
    end
  end
end
