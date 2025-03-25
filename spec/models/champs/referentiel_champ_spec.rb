# frozen_string_literal: true

require 'rails_helper'

describe Champs::ReferentielChamp, type: :model do
  let(:whitelist) { %w[https://rnb-api.beta.gouv.fr] }
  let(:referentiel) { create(:api_referentiel, :configured, url: whitelist.first) }
  let(:types_de_champ_public) { [{ type: :referentiel, referentiel: }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first.tap { _1.update(value:) } }
  let(:value) { "PG46YY6YWCX8" }

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
