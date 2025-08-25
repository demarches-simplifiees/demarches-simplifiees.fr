# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250825backfillChampExternalStateTask do
      describe "#process" do
        subject(:process) { described_class.process(champ) }
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :referentiel }]) }
        let(:dossier) { create(:dossier, procedure:) }
        let(:champ) { dossier.project_champs_public.first }

        context "when external_data_fetched? is true" do
          before { allow(champ).to receive(:external_data_fetched?).and_return(true) }

          it { expect { process }.to change { champ.external_state }.from("idle").to('fetched') }
        end

        context "when external_error_present? is true" do
          before { allow(champ).to receive(:external_error_present?).and_return(true) }

          it { expect { process }.to change { champ.external_state }.from("idle").to('external_error') }
        end
      end
    end
end
