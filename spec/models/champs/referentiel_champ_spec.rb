# frozen_string_literal: true

require 'rails_helper'

describe Champs::ReferentielChamp, type: :model do
  let(:referentiel) { create(:api_referentiel, :configured) }
  let(:types_de_champ_public) { [{ type: :referentiel, referentiel: }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:referentiel_champ) { dossier.champs.find(&:referentiel?) }

  def with_value(external_id:, data: {}, fetch_external_data_exceptions: [])
    referentiel_champ.tap do
      _1.external_id = external_id
      _1.data = data
      _1.fetch_external_data_exceptions = fetch_external_data_exceptions
    end
  end

  describe '#valid?' do
    context 'when external_id is nil and data is nil' do
      let(:state_not_filled) { { external_id: nil, data: nil } }

      it 'is valid' do
        expect(with_value(**state_not_filled).validate(:champs_public_value)).to be_truthy
      end
    end

    context 'when external_id is present but data is nil' do
      let(:state_to_be_fetched) { { external_id: "KTHXBYE", data: nil } }

      it 'is invalid' do
        expect(with_value(**state_to_be_fetched).validate(:champs_public_value)).to be_falsey
      end

      it 'adds the correct error message' do
        champ = with_value(**state_to_be_fetched)
        champ.validate(:champs_public_value)
        expect(champ.errors[:value]).to include(I18n.t('activerecord.errors.models.champs/referentiel_champ.attributes.value.api_response_pending'))
      end
    end

    context 'when external_id and data are present' do
      let(:state_fetched) { { external_id: "KTHXBYE", data: { ok: :ok } } }

      it 'is valid' do
        expect(with_value(**state_fetched).validate(:champs_public_value)).to be_truthy
      end
    end

    context 'when fetch_external_data_exceptions contains a non-retryable error' do
      let(:state_error) { { external_id: "KTHXBYE", data: nil, fetch_external_data_exceptions: [reason: 'Not retryable: 404, 400, 403, 401', code: 404] } }

      it 'is invalid' do
        expect(with_value(**state_error).validate(:champs_public_value)).to be_falsey
      end

      it 'adds the correct error message' do
        champ = with_value(**state_error)
        champ.validate(:champs_public_value)

        expect(champ.errors[:value]).to include(I18n.t('activerecord.errors.models.champs/referentiel_champ.attributes.value.code_404'))
      end
    end
  end

  describe 'updates external_id' do
    before do
      values = {
        value: '123',
        data: { ok: "ok" },
        value_json: { ok: "ok" },
        fetch_external_data_exceptions: ['error']
      }
      referentiel_champ.update!(values)
    end

    it 'propagate fetch_external_data_pending? changes and reset for values, data, value_json and fetch_external_data_exceptions' do
      expect { referentiel_champ.update(external_id: 'newid') }.to change { referentiel_champ.fetch_external_data_pending? }.from(false).to(true)

      expect(referentiel_champ.external_id).to eq('newid')
      expect(referentiel_champ.data).to eq(nil)
      expect(referentiel_champ.value_json).to eq(nil)
      expect(referentiel_champ.fetch_external_data_exceptions).to eq([])
    end
  end

  describe '#fetch_external_data' do
    subject { referentiel_champ.update_with_external_data!(data:) }

    context 'when referentiel had not prefill' do
      let(:data) { {} }
      let(:types_de_champ_public) { [type: :referentiel, referentiel: referentiel, referentiel_mapping: nil] }
      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

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
    end
  end
end
