# frozen_string_literal: true

require 'rails_helper'

describe Champs::ReferentielChamp, type: :model do
  let(:referentiel) { create(:api_referentiel, :exact_match, :configured) }
  let(:types_de_champ_public) { [{ type: :referentiel, referentiel: }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:referentiel_champ) { dossier.champs.find(&:referentiel?) }

  describe '#valid?' do
    def with_value(external_id:, data: {}, fetch_external_data_exceptions: [])
      referentiel_champ.tap do
        _1.external_id = external_id
        _1.data = data
        _1.fetch_external_data_exceptions = fetch_external_data_exceptions
      end
    end

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

    it 'propagate waiting_for_external_data? changes and reset for values, data, value_json and fetch_external_data_exceptions' do
      expect { referentiel_champ.update(external_id: 'newid') }.to change { referentiel_champ.waiting_for_external_data? }.from(false).to(true)

      expect(referentiel_champ.external_id).to eq('newid')
      expect(referentiel_champ.data).to eq(nil)
      expect(referentiel_champ.value_json).to eq(nil)
      expect(referentiel_champ.fetch_external_data_exceptions).to eq([])
    end
  end

  describe '#fetch_external_data' do
    subject { referentiel_champ.update_external_data!(data:) }

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

      describe 'when prefillable_stable_id has been destroyed' do
        let(:prefillable_stable_id) { 9999 }
        let(:prefilled_type_de_champ_type) { :text }

        it 'does not raise an error' do
          expect { subject }.to raise_error(StandardError)
        end
      end
    end
  end
end
