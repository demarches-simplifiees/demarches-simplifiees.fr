# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20251031backfillMissingEtablissementTask do
    describe "#process" do
      subject(:process) { described_class.process(element) }

      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :siret }]) }
      let(:dossier) { create(:dossier, procedure:) }
      let(:champ) { dossier.project_champs_public.first }
      let(:element) { { "champ_id" => champ.id.to_s } }

      context "when champ exists with external_id" do
        before do
          champ.update(external_id: "13002526500013")
        end

        it "resets and fetches external data" do
          expect_any_instance_of(Champs::SiretChamp).to receive(:reset_external_data!)
          expect_any_instance_of(Champs::SiretChamp).to receive(:fetch_later!)
          process
        end
      end

      context "when champ does not exist" do
        let(:element) { { "champ_id" => "999999" } }

        it "does nothing" do
          expect { process }.not_to raise_error
        end
      end

      context "when champ has no external_id" do
        before do
          champ.update(external_id: nil)
        end

        it "does nothing" do
          expect { process }.not_to raise_error
        end
      end
    end
  end
end
