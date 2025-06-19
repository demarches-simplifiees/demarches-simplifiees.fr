# frozen_string_literal: true

require 'rails_helper'

describe Champs::ReferentielChamp, type: :model do
  let(:referentiel) { create(:api_referentiel, :configured) }
  let(:types_de_champ_public) { [{ type: :referentiel, referentiel: }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:referentiel_champ) { dossier.champs.find(&:referentiel?) }

  describe '#cast_value_for_type_de_champ' do
    subject { referentiel_champ.update_with_external_data!(data:) }

    context 'when prefill/mapping is configured' do
      let(:prefillable_stable_id) { 2 }
      let(:prefilled_type_de_champ_options) { {} }
      let(:types_de_champ_public) do
        [
          {
            type: :referentiel,
            referentiel: referentiel,
            referentiel_mapping: {
              "$.ok" => { prefill: "1", prefill_stable_id: prefillable_stable_id }
            }
          },
          { type: prefilled_type_de_champ_type, stable_id: prefillable_stable_id }.merge(prefilled_type_de_champ_options)
        ]
      end

      describe 'when prefillable_stable_id has been destroyed' do
        let(:prefillable_stable_id) { 9999 }
        let(:prefilled_type_de_champ_type) { :text }

        it 'does not raise an error' do
          expect { subject }.to raise_error(StandardError)
        end
      end

      context 'when data is mapped to text' do
        let(:data) { { ok: 'ok' } }
        let(:prefilled_type_de_champ_type) { :text }

        it 'update the prefiiable stable_id with the jsonpath value of the external data' do
          expect { subject }
            .to change { dossier.reload.project_champs.find(&:text?).value }.from(nil).to("ok")
        end
      end

      context 'when data is mapped to integer_number' do
        let(:prefilled_type_de_champ_type) { :integer_number }

        context 'when data is a string integer' do
          let(:data) { { ok: "42" } }
          it 'casts and updates the integer_number with the jsonpath value as integer' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:integer_number?).value }.from(nil).to("42")
          end
        end

        context 'when data is an integer' do
          let(:data) { { ok: 42 } }
          it 'casts and updates the integer_number with the jsonpath value as integer' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:integer_number?).value }.from(nil).to("42")
          end
        end

        context 'when data is a float' do
          let(:data) { { ok: 42.2 } }
          it 'casts and updates the integer_number with the jsonpath value as integer' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:integer_number?).value }.from(nil).to("42")
          end
        end

        context 'when data is nil' do
          let(:data) { { ok: nil } }
          it 'casts and updates the integer_number with the jsonpath value as integer' do
            expect { subject }
              .not_to change { dossier.reload.project_champs.find(&:integer_number?).value }
          end
        end

        context 'when data is blank string' do
          let(:data) { { ok: "" } }
          it 'casts and updates the integer_number with the jsonpath value as integer' do
            expect { subject }
              .not_to change { dossier.reload.project_champs.find(&:integer_number?).value }
          end
        end
      end

      context 'when data is mapped to decimal_number' do
        let(:prefilled_type_de_champ_type) { :decimal_number }

        context 'when data is a float' do
          let(:data) { { ok: 3.14 } }
          it 'casts and updates the decimal_number with the jsonpath value as float' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:decimal_number?).value }.from(nil).to("3.14")
          end
        end

        context 'when data is a string float' do
          let(:data) { { ok: "3.14" } }
          it 'casts and updates the decimal_number with the jsonpath value as float' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:decimal_number?).value }.from(nil).to("3.14")
          end
        end

        context 'when data is an integer' do
          let(:data) { { ok: 2 } }
          it 'casts and updates the decimal_number with the jsonpath value as float' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:decimal_number?).value }.from(nil).to("2.0")
          end
        end

        context 'when data is a string integer' do
          let(:data) { { ok: "2" } }
          it 'casts and updates the decimal_number with the jsonpath value as float' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:decimal_number?).value }.from(nil).to("2.0")
          end
        end

        context 'when data is nil' do
          let(:data) { { ok: nil } }
          it 'does not update the decimal_number value (remains nil)' do
            expect { subject }
              .not_to change { dossier.reload.project_champs.find(&:decimal_number?).value }.from(nil)
          end
        end

        context 'when data is blank string' do
          let(:data) { { ok: "" } }
          it 'does not update the decimal_number value (remains nil)' do
            expect { subject }
              .not_to change { dossier.reload.project_champs.find(&:decimal_number?).value }.from(nil)
          end
        end
      end

      context 'when data is mapped to checkbox' do
        let(:prefilled_type_de_champ_type) { :checkbox }

        context 'when data is true' do
          let(:data) { { ok: true } }
          it 'casts and updates the checkbox with the jsonpath value as "true"' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:checkbox?).value }.from(nil).to("true")
          end
        end

        context 'when data is string "true"' do
          let(:data) { { ok: "true" } }
          it 'casts and updates the checkbox with the jsonpath value as "true"' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:checkbox?).value }.from(nil).to("true")
          end
        end

        context 'when data is 1' do
          let(:data) { { ok: 1 } }
          it 'casts and updates the checkbox with the jsonpath value as "true"' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:checkbox?).value }.from(nil).to("true")
          end
        end

        context 'when data is string "1"' do
          let(:data) { { ok: "1" } }
          it 'casts and updates the checkbox with the jsonpath value as "true"' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:checkbox?).value }.from(nil).to("true")
          end
        end

        context 'when data is nil' do
          let(:data) { { ok: nil } }
          it 'does not update the checkbox value (remains nil)' do
            expect { subject }
              .not_to change { dossier.reload.project_champs.find(&:checkbox?).value }.from(nil)
          end
        end

        context 'when data is empty string' do
          let(:data) { { ok: "" } }
          it 'does not update the checkbox value (remains nil)' do
            expect { subject }
              .not_to change { dossier.reload.project_champs.find(&:checkbox?).value }.from(nil)
          end
        end
      end

      context 'when data is mapped to yes_no' do
        let(:prefilled_type_de_champ_type) { :yes_no }

        context 'when data is false' do
          let(:data) { { ok: false } }
          it 'casts and updates the yes_no with the jsonpath value as "false"' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:yes_no?).value }.from(nil).to("false")
          end
        end

        context 'when data is string "false"' do
          let(:data) { { ok: "false" } }
          it 'casts and updates the yes_no with the jsonpath value as "false"' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:yes_no?).value }.from(nil).to("false")
          end
        end

        context 'when data is 0' do
          let(:data) { { ok: 0 } }
          it 'casts and updates the yes_no with the jsonpath value as "false"' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:yes_no?).value }.from(nil).to("false")
          end
        end

        context 'when data is string "0"' do
          let(:data) { { ok: "0" } }
          it 'casts and updates the yes_no with the jsonpath value as "false"' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:yes_no?).value }.from(nil).to("false")
          end
        end

        context 'when data is nil' do
          let(:data) { { ok: nil } }
          it 'does not update the yes_no value (remains nil)' do
            expect { subject }
              .not_to change { dossier.reload.project_champs.find(&:yes_no?).value }.from(nil)
          end
        end

        context 'when data is empty string' do
          let(:data) { { ok: "" } }
          it 'does not update the yes_no value (remains nil)' do
            expect { subject }
              .not_to change { dossier.reload.project_champs.find(&:yes_no?).value }.from(nil)
          end
        end
      end

      context 'when data is mapped to date' do
        let(:prefilled_type_de_champ_type) { :date }

        context 'when data is ISO8601 date' do
          let(:data) { { ok: '2024-06-14' } }
          it 'casts and updates the date with the jsonpath value as ISO8601' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:date?).value }.from(nil).to('2024-06-14')
          end
        end

        context 'when data is dd/mm/yyyy' do
          let(:data) { { ok: '14/06/2024' } }
          it 'casts and updates the date with the jsonpath value as ISO8601' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:date?).value }.from(nil).to('2024-06-14')
          end
        end

        context 'when data is invalid date' do
          let(:data) { { ok: '2024-13-14' } }
          it 'does not update the date value (remains nil)' do
            expect { subject }
              .not_to change { dossier.reload.project_champs.find(&:date?).value }.from(nil)
          end
        end
      end

      context 'when data is mapped to datetime' do
        let(:prefilled_type_de_champ_type) { :datetime }

        context 'when data is ISO8601 datetime' do
          let(:data) { { ok: '2024-06-14T12:34' } }
          it 'casts and updates the datetime with the jsonpath value as ISO8601' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:datetime?).value }.from(nil).to(Time.zone.parse('2024-06-14T12:34').iso8601)
          end
        end

        context 'when data is dd/mm/yyyy hh:mm' do
          let(:data) { { ok: '14/06/2024 12:34' } }
          it 'casts and updates the datetime with the jsonpath value as ISO8601' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:datetime?).value }.from(nil).to(Time.zone.parse('2024-06-14T12:34').iso8601)
          end
        end

        context 'when data is invalid datetime' do
          let(:data) { { ok: '2024-06-14T25:00' } }
          it 'does not update the datetime value (remains nil)' do
            expect { subject }
              .not_to change { dossier.reload.project_champs.find(&:datetime?).value }.from(nil)
          end
        end
      end

      context 'when data is mapped to drop_down_list' do
        let(:prefilled_type_de_champ_type) { :drop_down_list }

        context 'when data is in options' do
          let(:prefilled_type_de_champ_options) { { options: ['valid'] } }
          let(:data) { { ok: 'valid' } }
          it 'casts and updates the drop_down_list with the jsonpath value as string' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:drop_down_list?).value }.from(nil).to('valid')
          end
        end

        context 'when data is not in options without other' do
          let(:prefilled_type_de_champ_options) { { options: ['valid'] } }
          let(:data) { { ok: 'invalid' } }
          it 'does not cast' do
            expect { subject }
              .not_to change { dossier.reload.project_champs.find(&:drop_down_list?).value }
          end
        end

        context 'when data is not in options with other' do
          let(:prefilled_type_de_champ_options) { { options: ['valid'] + [:other] } }
          let(:data) { { ok: 'anything' } }
          it 'allows other' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:drop_down_list?).value }.from(nil).to('anything')
          end
        end

        context 'when data is nil' do
          let(:data) { { ok: nil } }
          it 'does not update the drop_down_list value (remains nil)' do
            expect { subject }
              .not_to change { dossier.reload.project_champs.find(&:drop_down_list?).value }.from(nil)
          end
        end
      end

      context 'when data is mapped to multiple_drop_down_list' do
        let(:prefilled_type_de_champ_type) { :multiple_drop_down_list }
        let(:prefilled_type_de_champ_options) { { options: ['valid', 'valid_one', 'valid_two'] } }

        context 'when data is an array of strings' do
          let(:data) { { ok: ['valid', 'valid_one'] } }
          it 'casts and updates the multiple_drop_down_list with the jsonpath value as JSON array' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:multiple_drop_down_list?).value }.from(nil).to(['valid', 'valid_one'].to_json)
          end
        end

        context 'when data is an array of object' do
          let(:data) { { ok: [{ choice: '1' }, { choice: '2' }] } }
          it 'passthru' do
            expect { subject }
              .not_to change { dossier.reload.project_champs.find(&:multiple_drop_down_list?).value }
          end
        end

        context 'when data is nil' do
          let(:data) { { ok: nil } }
          it 'does not update the multiple_drop_down_list value (remains nil)' do
            expect { subject }
              .not_to change { dossier.reload.project_champs.find(&:multiple_drop_down_list?).value }.from(nil)
          end
        end

        context 'when data contains invalid options' do
          let(:data) { { ok: ['valid', 'invalid_option'] } }
          it 'allows invalid value due to validation afterward' do
            expect { subject }
              .to change { dossier.reload.project_champs.find(&:multiple_drop_down_list?).value }.from(nil).to(['valid', 'invalid_option'].to_json)
          end
        end
      end

      context 'when data is mapped to formatted' do
        let(:prefilled_type_de_champ_type) { :formatted }
        let(:data) { { ok: 'texte <b>formaté</b>' } }
        it 'update le champ formatted avec la valeur string' do
          expect { subject }
            .to change { dossier.reload.project_champs.find(&:formatted?).value }.from(nil).to('texte <b>formaté</b>')
        end
      end

      context 'when data is mapped to child' do
        let(:types_de_champ_public) do
          [
            {
              type: :referentiel,
              referentiel: referentiel,
              referentiel_mapping: {
                "$.ok[0].nom" => { prefill: "1", prefill_stable_id: 1 },
                "$.ok[1].age" => { prefill: "1", prefill_stable_id: 2 }
              }
            },
            {
              type: :repetition,
              children: [
                { type: :text, stable_id: 1 },
                { type: :number, stable_id: 2 }
              ]
            }
          ]
        end
        let(:data) { { ok: [{ nom: 'Jeanne', age: 120 }, { nom: "Bob", age: 12 }, {}] } }
        it 'update le champ formatted avec la valeur string' do
          subject
          values = dossier.reload.champs.filter(&:text?).map(&:value)
          expect(values).to include('Jeanne')
          expect(values).to include('Bob')
        end
      end
    end
  end
end
