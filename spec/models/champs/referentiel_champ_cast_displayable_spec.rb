# frozen_string_literal: true

require 'rails_helper'

describe Champs::ReferentielChamp, type: :model do
  let(:referentiel) { create(:api_referentiel, :configured) }
  let(:types) { Referentiels::MappingFormComponent::TYPES }
  let(:types_de_champ_public) { [{ type: :referentiel, referentiel: }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:referentiel_champ) { dossier.champs.find(&:referentiel?) }

  describe '#cast_displayable_values' do
    subject { referentiel_champ.update_with_external_data!(data:) }

    context 'when displayable mapping is configured for string' do
      let(:types_de_champ_public) do
        [
          {
            type: :referentiel,
            referentiel: referentiel,
            referentiel_mapping: {
              "$.string" => { type: types[:string], display_usager: "1" }
            }
          }
        ]
      end
      let(:data) { { string: "abc" } }

      it 'casts and stores displayable string value for usager' do
        referentiel_champ.update_with_external_data!(data: data)
<<<<<<< HEAD
        expect(referentiel_champ.value_json.with_indifferent_access["$.string"]).to eq("abc")
=======
        expect(referentiel_champ.value_json.with_indifferent_access[:display_usager]["$.string"]).to eq("abc")
>>>>>>> b9ff70eba5 (feat(ReferentielChamp): map, cast and store choosen jsonpath from api responses to be shown to usager and/or instructeur)
      end
    end

    context 'when displayable mapping is configured for float' do
      let(:types_de_champ_public) do
        [
          {
            type: :referentiel,
            referentiel: referentiel,
            referentiel_mapping: {
              "$.float" => { type: types[:decimal_number], display_usager: "1" }
            }
          }
        ]
      end
      let(:data) { { float: 3.14 } }

      it 'casts and stores displayable float value for usager' do
        referentiel_champ.update_with_external_data!(data: data)
<<<<<<< HEAD
        expect(referentiel_champ.value_json.with_indifferent_access["$.float"]).to eq(3.14)
=======
        expect(referentiel_champ.value_json.with_indifferent_access[:display_usager]["$.float"]).to eq(3.14)
>>>>>>> b9ff70eba5 (feat(ReferentielChamp): map, cast and store choosen jsonpath from api responses to be shown to usager and/or instructeur)
      end
    end

    context 'when displayable mapping is configured for integer' do
      let(:types_de_champ_public) do
        [
          {
            type: :referentiel,
            referentiel: referentiel,
            referentiel_mapping: {
              "$.int" => { type: types[:integer_number], display_usager: "1" }
            }
          }
        ]
      end
      let(:data) { { int: 42 } }

      it 'casts and stores displayable integer value for usager' do
        referentiel_champ.update_with_external_data!(data: data)
<<<<<<< HEAD
        expect(referentiel_champ.value_json.with_indifferent_access["$.int"]).to eq(42)
=======
        expect(referentiel_champ.value_json.with_indifferent_access[:display_usager]["$.int"]).to eq(42)
>>>>>>> b9ff70eba5 (feat(ReferentielChamp): map, cast and store choosen jsonpath from api responses to be shown to usager and/or instructeur)
      end
    end

    context 'when displayable mapping is configured for boolean' do
      let(:types_de_champ_public) do
        [
          {
            type: :referentiel,
            referentiel: referentiel,
            referentiel_mapping: {
              "$.bool" => { type: types[:boolean], display_usager: "1" }
            }
          }
        ]
      end

      context 'when true' do
        let(:data) { { bool: true } }

        it 'casts and stores displayable boolean value for usager' do
          referentiel_champ.update_with_external_data!(data: data)
<<<<<<< HEAD
          expect(referentiel_champ.value_json.with_indifferent_access["$.bool"]).to eq(true)
=======
          expect(referentiel_champ.value_json.with_indifferent_access[:display_usager]["$.bool"]).to eq(true)
>>>>>>> b9ff70eba5 (feat(ReferentielChamp): map, cast and store choosen jsonpath from api responses to be shown to usager and/or instructeur)
        end
      end

      context 'when false' do
        let(:data) { { bool: false } }

        it 'casts and stores displayable boolean value for usager' do
          referentiel_champ.update_with_external_data!(data: data)
<<<<<<< HEAD
          expect(referentiel_champ.value_json.with_indifferent_access["$.bool"]).to eq(false)
=======
          expect(referentiel_champ.value_json.with_indifferent_access[:display_usager]["$.bool"]).to eq(false)
>>>>>>> b9ff70eba5 (feat(ReferentielChamp): map, cast and store choosen jsonpath from api responses to be shown to usager and/or instructeur)
        end
      end
    end

    context 'when displayable mapping is configured for date' do
      let(:types_de_champ_public) do
        [
          {
            type: :referentiel,
            referentiel: referentiel,
            referentiel_mapping: {
              "$.date" => { type: types[:date], display_usager: "1" }
            }
          }
        ]
      end
      let(:data) { { date: "2024-06-19" } }

      it 'casts and stores displayable date value for usager' do
        referentiel_champ.update_with_external_data!(data: data)
<<<<<<< HEAD
        expect(referentiel_champ.value_json.with_indifferent_access["$.date"]).to eq("2024-06-19")
=======
        expect(referentiel_champ.value_json.with_indifferent_access[:display_usager]["$.date"]).to eq("2024-06-19")
>>>>>>> b9ff70eba5 (feat(ReferentielChamp): map, cast and store choosen jsonpath from api responses to be shown to usager and/or instructeur)
      end
    end

    context 'when displayable mapping is configured for datetime' do
      let(:types_de_champ_public) do
        [
          {
            type: :referentiel,
            referentiel: referentiel,
            referentiel_mapping: {
              "$.datetime" => { type: types[:datetime], display_usager: "1" }
            }
          }
        ]
      end
      let(:data) { { datetime: "2024-06-19T15:30" } }

      it 'casts and stores displayable datetime value for usager' do
        referentiel_champ.update_with_external_data!(data: data)
<<<<<<< HEAD
        expect(referentiel_champ.value_json.with_indifferent_access["$.datetime"]).to eq("2024-06-19T15:30:00+02:00")
=======
        expect(referentiel_champ.value_json.with_indifferent_access[:display_usager]["$.datetime"]).to eq("2024-06-19T15:30:00+02:00")
>>>>>>> b9ff70eba5 (feat(ReferentielChamp): map, cast and store choosen jsonpath from api responses to be shown to usager and/or instructeur)
      end
    end

    context 'when displayable mapping is configured for Liste à choix multiples' do
      let(:types_de_champ_public) do
        [
          {
            type: :referentiel,
            referentiel: referentiel,
            referentiel_mapping: {
              "$.list" => { type: types[:array], display_usager: "1" }
            }
          }
        ]
      end
      let(:data) { { list: ["a", "b", "c"] } }

      it 'casts and stores displayable list value for usager' do
        referentiel_champ.update_with_external_data!(data: data)
<<<<<<< HEAD
        expect(referentiel_champ.value_json.with_indifferent_access["$.list"]).to eq(["a", "b", "c"])
=======
        expect(referentiel_champ.value_json.with_indifferent_access[:display_usager]["$.list"]).to eq(["a", "b", "c"])
>>>>>>> b9ff70eba5 (feat(ReferentielChamp): map, cast and store choosen jsonpath from api responses to be shown to usager and/or instructeur)
      end
    end
  end
end
