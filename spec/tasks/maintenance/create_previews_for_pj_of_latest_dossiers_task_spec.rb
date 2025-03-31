# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe CreatePreviewsForPjOfLatestDossiersTask do
    describe "#process" do
      let(:procedure) { create(:procedure_with_dossiers) }
      let(:dossier) { procedure.dossiers.first }
      let(:type_de_champ_pj) { create(:type_de_champ_piece_justificative, stable_id: 3, libelle: 'Justificatif de domicile', procedure:) }
      let(:champ_pj) { create(:champ_piece_justificative, type_de_champ: type_de_champ_pj, dossier:) }
      let(:blob_info) do
        {
          filename: file.original_filename,
          byte_size: file.size,
          checksum: Digest::SHA256.file(file.path),
          content_type: file.content_type,
          # we don't want to run virus scanner on this file
          metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
        }
      end
      let(:blob) do
        blob = ActiveStorage::Blob.create_before_direct_upload!(**blob_info)
        blob.upload(file)
        blob
      end

      let(:attachment) { ActiveStorage::Attachment.create(name: "test", blob: blob, record: champ_pj) }

      before do
        dossier.update(
          depose_at: Date.new(2024, 05, 23),
          state: "en_construction"
        )
      end

      subject(:process) { described_class.process(dossier) }

      context "when pj is a pdf" do
        let(:file) { fixture_file_upload('spec/fixtures/files/RIB.pdf', 'application/pdf') }

        it "creates a preview" do
          expect(attachment.preview(resize_to_limit: [400, 400]).image.attached?).to be false
          expect { subject }.to change { attachment.reload.preview(resize_to_limit: [400, 400]).image.attached? }
        end
      end
    end
  end
end
