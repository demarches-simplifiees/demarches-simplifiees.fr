# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe CreatePreviewsForPjOfLatestDossiersTask do
    describe "#process" do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative, stable_id: 3, libelle: 'Justificatif de domicile' }]) }
      let(:dossier) { create(:dossier, procedure:) }
      let(:champ_pj) { dossier.champs.first }

      before do
        champ_pj.piece_justificative_file.attach(
          io: file,
          filename: file.original_filename,
          content_type:  file.content_type,
          metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
        )
        dossier.update(
          depose_at: Date.new(2024, 05, 23),
          state: "en_construction"
        )
      end

      subject(:process) { described_class.process(dossier) }

      context "when pj is a pdf" do
        let(:file) { fixture_file_upload('spec/fixtures/files/RIB.pdf', 'application/pdf') }

        it "creates a preview", :external_deps do
          attachment = champ_pj.piece_justificative_file.attachments.first
          expect(attachment.preview(resize_to_limit: [400, 400]).image.attached?).to be false
          expect { subject }.to change { attachment.reload.preview(resize_to_limit: [400, 400]).image.attached? }
        end
      end
    end
  end
end
