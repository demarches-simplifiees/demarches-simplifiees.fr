# frozen_string_literal: true

require 'rails_helper'

describe Champs::ReferentielChamp, type: :model do
  let(:whitelist) { %w[https://rnb-api.beta.gouv.fr] }
  let(:types_de_champ_public) { [{ type: :referentiel, referentiel: create(:api_referentiel, url: whitelist.first) }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first.tap { _1.update(value:) } }
  let(:value) { "PG46YY6YWCX8" }
  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('API_WHITELIST', '').and_return(whitelist.join(','))
  end
  def with_value(value:, data:)
    champ.tap do
      _1.value = value
      _1.data = data
    end
  end

  describe '#valid?' do
    it { expect(with_value(value: nil, data: nil).validate(:champs_public_value)).to be_truthy }
    it { expect(with_value(value: "KTHXBYE", data: nil).validate(:champs_public_value)).to be_falsey }
    it { expect(with_value(value: "KTHXBYE", data: { ok: :ok }).validate(:champs_public_value)).to be_truthy }
  end
end
