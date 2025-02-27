# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250226FixDossiersEnInstructionWithPendingCorrectionTask do
    let(:instructeur) { create(:instructeur) }
    let(:dossier) { create(:dossier, :en_instruction) }
    let(:commentaire) { create(:commentaire, dossier:, instructeur:) }

    before do
      dossier.flag_as_pending_correction!(commentaire)
      dossier.update(state: "en_instruction")
    end

    describe "#process" do
      subject(:process) { described_class.process(dossier) }

      it "repasse le dossier en construction avec la correction toujours en attente" do
        expect(dossier).to be_en_instruction
        expect(dossier.corrections.one?(&:pending?)).to be_truthy
        process
        dossier.reload
        expect(dossier).to be_en_construction
        expect(dossier.corrections.one?(&:pending?)).to be_truthy
      end

      it "does not send any email" do
        expect { perform_enqueued_jobs { process } }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it "creates operation log" do
        expect { process }.to change { DossierOperationLog.count }.by(1)
        log = DossierOperationLog.last
        expect(log.data["author"]).to eq(DossierOperationLog.serialize_author(instructeur))
        expect(log).to be_repasser_en_construction
      end

      context "when something fails during transaction" do
        before do
          allow(dossier).to receive(:repasser_en_construction!).and_raise("boom")
        end

        it "rolls back all changes" do
          expect(dossier).to be_en_instruction
          process
          dossier.reload
          expect(dossier).to be_en_instruction
          expect(dossier.corrections.one?(&:pending?)).to be_truthy
        end
      end
    end
  end
end
