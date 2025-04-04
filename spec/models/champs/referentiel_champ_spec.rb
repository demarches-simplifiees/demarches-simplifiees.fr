# frozen_string_literal: true

require 'rails_helper'

describe Champs::ReferentielChamp, type: :model do
  let(:whitelist) { %w[https://rnb-api.beta.gouv.fr] }
  let(:referentiel) { create(:api_referentiel, :configured, url: whitelist.first) }
  let(:types_de_champ_public) { [{ type: :referentiel, referentiel: }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:value) { "PG46YY6YWCX8" }
  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('ALLOWED_API_DOMAINS_FROM_FRONTEND', '').and_return(whitelist.join(','))
  end

  def with_value(value:, data:)
    champ.tap do
      _1.value = value
      _1.data = data
    end
  end

  describe '#valid?' do
    let(:champ) { dossier.champs.first.tap { _1.update(value:) } }

    it { expect(with_value(value: nil, data: nil).validate(:champs_public_value)).to be_truthy }
    it { expect(with_value(value: "KTHXBYE", data: nil).validate(:champs_public_value)).to be_falsey }
    it { expect(with_value(value: "KTHXBYE", data: { ok: :ok }).validate(:champs_public_value)).to be_truthy }
  end

  describe 'updates external_id' do
    let(:champ) { dossier.champs.first }
    before do
      values =  {
        value: '123',
        data: { ok: "ok" },
        value_json: { ok: "ok" },
        fetch_external_data_exceptions: ['error']
      }
      champ.update!(values)
    end

    it 'propagate fetch_external_data_pending? changes and reset for values, data, value_json and fetch_external_data_exceptions' do
      expect { champ.update(external_id: 'newid') }.to change { champ.fetch_external_data_pending? }.from(false).to(true)

      expect(champ.external_id).to eq('newid')
      expect(champ.data).to eq(nil)
      expect(champ.value_json).to eq(nil)
      expect(champ.fetch_external_data_exceptions).to eq([])
    end
  end
end
