# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250304BackfillTraitementRevisionIdTask do
    let(:dossiers) { create_list(:dossier, 2, :en_construction) }
    let(:dossier) { dossiers.first }
    let(:traitement) { dossier.traitements.first }
    let(:last_revision) { dossier.procedure.revisions.first }
    let(:previous_revision) { dossier.procedure.revisions.second }

    before do
      traitement.update(revision_id: nil)
    end

    describe "#process" do
      subject(:process) { described_class.process(traitement) }

      context "when dossier depose on last revision" do
        before do
          last_revision.update(published_at: traitement.processed_at - 1.minute)
          previous_revision.update(published_at: traitement.processed_at - 2.minutes)
        end

        it { expect { process }.to change { traitement.reload.revision }.from(nil).to(last_revision) }
      end

      context "when dossier depose on previous revision" do
        before do
          last_revision.update(published_at: traitement.processed_at + 1.minute)
          previous_revision.update(published_at: traitement.processed_at - 1.minute)
        end

        it { expect { process }.to change { traitement.reload.revision }.from(nil).to(previous_revision) }
      end
    end

    describe "#collection" do
      subject(:collection) { described_class.collection }

      it "returns the correct collection" do
        expect(collection.size).to eq(1)
      end
    end
  end
end
