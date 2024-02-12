describe TitreIdentiteWatermarkJob, type: :job do
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new("toto"), filename: "toto.png")
  end

  let(:antivirus_pending) { false }
  let(:watermark_service) { instance_double("WatermarkService") }

  before do
    virus_scanner_mock = instance_double("ActiveStorage::VirusScanner", pending?: antivirus_pending)
    allow(blob).to receive(:virus_scanner).and_return(virus_scanner_mock)

    allow(WatermarkService).to receive(:new).and_return(watermark_service)
    allow(watermark_service).to receive(:process).and_return(true)
  end

  context "when watermark is already done" do
    before do
      allow(blob).to receive(:watermark_done?).and_return(true)
    end

    it "does not process the blob" do
      expect(watermark_service).not_to receive(:process)
      described_class.perform_now(blob)
    end
  end

  context "when the blob is not scanned yet" do
    let(:antivirus_pending) { true }

    it "raises a FileNotScannedYetError" do
      expect { described_class.perform_now(blob) }.to have_enqueued_job(described_class).with(blob)
    end
  end

  context "when the blob is ready to be watermarked" do
    let(:watermarked_file) { Tempfile.new("watermarked.png") }

    before do
      allow(watermarked_file).to receive(:size).and_return(100)
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
