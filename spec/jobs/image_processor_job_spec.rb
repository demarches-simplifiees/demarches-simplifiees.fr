# frozen_string_literal: true

describe ImageProcessorJob, type: :job do
  let(:antivirus_pending) { false }
  let(:watermark_service) { instance_double("WatermarkService") }
  let(:auto_rotate_service) { instance_double("AutoRotateService") }
  let(:uninterlace_service) { instance_double("UninterlaceService") }

  let(:file) { fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png') }

  let(:procedure) do
    create(:procedure).tap {
      # Skip notice validator on format
      allow(_1).to receive(:valid?).and_return(true)
    }
  end

  let(:blob) do
    procedure.notice.attach(file)
    procedure.notice.blob
  end

  before do
   virus_scanner_mock = instance_double("ActiveStorage::VirusScanner", pending?: antivirus_pending)

   allow(blob).to receive(:virus_scanner).and_return(virus_scanner_mock)

   allow(WatermarkService).to receive(:new).and_return(watermark_service)
   allow(watermark_service).to receive(:process).and_return(true)
 end

  context "when the blob is not scanned yet" do
    let(:antivirus_pending) { true }

    it "raises a FileNotScannedYetError" do
      expect { described_class.perform_now(blob) }.to have_enqueued_job(described_class).with(blob)
    end
  end

  describe 'autorotate' do
    before do
      allow(AutoRotateService).to receive(:new).and_return(auto_rotate_service)
      allow(auto_rotate_service).to receive(:process).and_return(true)
    end

    context "when image is not a jpg" do
      it "it does not process autorotate" do
        expect(auto_rotate_service).not_to receive(:process)
        described_class.perform_now(blob)
      end
    end

    context "when image is a jpg" do
      let(:rotated_file) { Tempfile.new("rotated.jpg") }
      let(:file) { fixture_file_upload('spec/fixtures/files/image-rotated.jpg', 'image/jpeg') }

      before do
        allow(rotated_file).to receive(:size).and_return(100)
      end

      it "it processes autorotate" do
        expect(auto_rotate_service).to receive(:process).and_return(rotated_file)
        described_class.perform_now(blob)
      end
    end
  end

  describe 'create representation' do
    context "when type image is usual" do
      context "when representation is not required" do
        it "it does not create blob representation" do
          expect { described_class.perform_now(blob) }.not_to change { ActiveStorage::VariantRecord.count }
        end
      end

      context "when representation is required" do
        before do
          allow(blob).to receive(:representation_required?).and_return(true)
        end

        it "it creates blob representation" do
          expect { described_class.perform_now(blob) }.to change { ActiveStorage::VariantRecord.count }.by(1)
        end
      end
    end

    context "when type image is rare" do
      let(:file) { fixture_file_upload('spec/fixtures/files/pencil.tiff', 'image/tiff') }

      before do
        allow(blob).to receive(:representation_required?).and_return(true)
      end

      it "creates a second variant" do
        expect { described_class.perform_now(blob) }.to change { ActiveStorage::VariantRecord.count }.by(2)
      end
    end
  end

  describe 'watermark' do
    context "when watermark is already done" do
      before do
        allow(blob).to receive(:watermark_done?).and_return(true)
      end

      it "does not process the watermark" do
        expect(watermark_service).not_to receive(:process)
        described_class.perform_now(blob)
      end
    end

    context "when the blob is ready to be watermarked" do
      let(:watermarked_file) { Tempfile.new("watermarked.jpg") }

      before do
        allow(watermarked_file).to receive(:size).and_return(100)
        allow(blob).to receive(:watermark_pending?).and_return(true)
      end

      it "processes the blob with watermark" do
        expect(watermark_service).to receive(:process).and_return(watermarked_file)

        expect {
          described_class.perform_now(blob)
        }.to change {
          blob.reload.checksum
        }

        expect(blob.byte_size).to eq(100)
        expect(blob.watermarked_at).to be_present
      end
    end
  end

  describe 'uninterlace' do
    before do
      allow(UninterlaceService).to receive(:new).and_return(uninterlace_service)
    end

    context "when file is interlaced" do
      let(:uninterlaced_file) {
        fixture_file_upload('spec/fixtures/files/uninterlaced-black.png', 'image/png')
      }

      it "it process uninterlace" do
        expect(uninterlace_service).to receive(:process).and_return(uninterlaced_file)
        described_class.perform_now(blob)
      end
    end
  end

  describe 'add ocr data' do
    let(:ocr_service) { instance_double("OcrService") }
    let(:procedure) do
      create(:procedure,
             types_de_champ_public: [{ type: :piece_justificative, nature: }])
    end
    let(:nature) { "RIB" }

    let (:dossier) { create(:dossier, procedure:) }
    let(:analysis) { { "some" => "data" } }

    let(:blob) do
      pj = dossier.project_champs_public.first.piece_justificative_file
      pj = pj.attach(file)
      pj.blobs.first
    end

    before do
      allow(Flipper).to receive(:enabled?).with(:ocr, blob).and_return(true)
      allow(OCRService).to receive(:analyze).and_return(analysis)

      described_class.perform_now(blob)
    end

    context "when the blob contains a RIB" do
      it "calls OcrService.analyze with the blob" do
        expect(blob.ocr).to eq(analysis)
      end
    end

    context "when the blob does not contain a RIB" do
      let(:nature) { nil }

      it "does not call OcrService.analyze nor set ocr data" do
        expect(OCRService).not_to have_received(:analyze)
        expect(blob.ocr).to be_nil
      end
    end

    context "when the blob is not a champ a RIB" do
      let(:blob) do
        procedure.notice.attach(file)
        procedure.notice.blob
      end

      it "does not call OcrService.analyze nor set ocr data" do
        expect(OCRService).not_to have_received(:analyze)
        expect(blob.ocr).to be_nil
      end
    end
  end
end
