describe ImageProcessorJob, type: :job do
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new("toto"), filename: "toto.png")
  end

  let(:blob_jpg) do
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new("toto"), filename: "toto.jpg")
  end

  let(:attachment) { ActiveStorage::Attachment.new(name: "test", blob: blob) }
  let(:antivirus_pending) { false }
  let(:watermark_service) { instance_double("WatermarkService") }
  let(:auto_rotate_service) { instance_double("AutoRotateService") }

  before do
    virus_scanner_mock = instance_double("ActiveStorage::VirusScanner", pending?: antivirus_pending)
    allow(blob).to receive(:attachments).and_return([attachment])

    allow(blob).to receive(:virus_scanner).and_return(virus_scanner_mock)
    allow(blob_jpg).to receive(:virus_scanner).and_return(virus_scanner_mock)

    allow(WatermarkService).to receive(:new).and_return(watermark_service)
    allow(watermark_service).to receive(:process).and_return(true)

    allow(AutoRotateService).to receive(:new).and_return(auto_rotate_service)
    allow(auto_rotate_service).to receive(:process).and_return(true)
  end

  context "when the blob is not scanned yet" do
    let(:antivirus_pending) { true }

    it "raises a FileNotScannedYetError" do
      expect { described_class.perform_now(blob) }.to have_enqueued_job(described_class).with(blob)
    end
  end

  describe 'autorotate' do
    context "when image is not a jpg" do
      let(:rotated_file) { Tempfile.new("rotated.png") }

      before do
        allow(rotated_file).to receive(:size).and_return(100)
      end

      it "it does not process autorotate" do
        expect(auto_rotate_service).not_to receive(:process)
        described_class.perform_now(blob)
      end
    end

    context "when image is a jpg " do
      let(:rotated_file) { Tempfile.new("rotated.jpg") }

      before do
        allow(rotated_file).to receive(:size).and_return(100)
      end

      it "it processes autorotate" do
        expect(auto_rotate_service).to receive(:process).and_return(rotated_file)
        described_class.perform_now(blob_jpg)
      end
    end
  end

  describe 'create representation' do
    let(:file) { fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png') }
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
      let(:watermarked_file) { Tempfile.new("watermarked.png") }

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
end
