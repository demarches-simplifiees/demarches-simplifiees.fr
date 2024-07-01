RSpec.describe GalleryHelper, type: :helper do
  let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
  let(:types_de_champ_public) { [{ type: :piece_justificative, stable_id: 3, libelle: 'Justificatif de domicile' }] }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:champ_pj) { dossier.champs.first }

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

  describe ".variant_url_for" do
    subject { variant_url_for(attachment) }

    context "when image attachment has a variant" do
      let(:file) { fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png') }

      before { attachment.variant(resize_to_limit: [400, 400]).processed }

      it { is_expected.not_to eq("apercu-indisponible.png") }
    end

    context "when image attachment has no variant" do
      let(:file) { fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png') }

      it { expect { subject }.not_to change { ActiveStorage::VariantRecord.count } }
      it { is_expected.to eq("apercu-indisponible.png") }
    end

    context "when attachment cannot be represented with a variant" do
      let(:file) { fixture_file_upload('spec/fixtures/files/instructeurs-file.csv', 'text/csv') }

      it { expect { subject }.not_to change { ActiveStorage::VariantRecord.count } }
      it { is_expected.to eq("apercu-indisponible.png") }
    end
  end

  describe ".preview_url_for" do
    subject { preview_url_for(attachment) }

    context "when pdf attachment has a preview" do
      let(:file) { fixture_file_upload('spec/fixtures/files/RIB.pdf', 'application/pdf') }

      before { attachment.preview(resize_to_limit: [400, 400]).processed }

      it { is_expected.not_to eq("pdf-placeholder.png") }
    end

    context "when pdf attachment has no preview" do
      let(:file) { fixture_file_upload('spec/fixtures/files/RIB.pdf', 'application/pdf') }

      it { expect { subject }.not_to change { ActiveStorage::VariantRecord.count } }
      it { is_expected.to eq("pdf-placeholder.png") }
    end

    context "when attachment cannot be represented with a preview" do
      let(:file) { fixture_file_upload('spec/fixtures/files/instructeurs-file.csv', 'text/csv') }

      it { expect { subject }.not_to change { ActiveStorage::VariantRecord.count } }
      it { is_expected.to eq("pdf-placeholder.png") }
    end
  end
end
