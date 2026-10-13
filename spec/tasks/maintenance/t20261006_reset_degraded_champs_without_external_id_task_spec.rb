# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20261006ResetDegradedChampsWithoutExternalIdTask do
    let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :siret }]) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champ_data.first }

    describe "#collection" do
      before { champ.update_columns(external_id:, value: external_id, external_state: 'degraded') }

      context "with a degraded champ emptied by the cleanup of hidden champs" do
        let(:external_id) { nil }

        it { expect(described_class.collection).to include(champ) }
      end

      context "with a degraded champ still holding its SIRET" do
        let(:external_id) { '30613890001294' }

        it { expect(described_class.collection).not_to include(champ) }
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(champ) }

      before do
        champ.update_columns(external_id: nil, value: nil, external_state: 'degraded',
          fetch_external_data_exceptions: [ExternalDataException.new(error: 'API Entreprise: unreadable_payload', code: 200)])
      end

      it "puts the champ back at rest, so it no longer blocks the decision" do
        process
        champ.reload

        expect(champ).to be_idle
        expect(champ.fetch_external_data_exceptions).to be_empty
        expect(dossier.reload.awaiting_external_verification?).to be false
      end

      context "when the usager typed a SIRET again in the meantime" do
        before { champ.update_columns(external_id: '30613890001294', value: '30613890001294') }

        it "leaves it to the cron" do
          expect { process }.not_to change { champ.reload.external_state }
        end
      end
    end
  end
end
