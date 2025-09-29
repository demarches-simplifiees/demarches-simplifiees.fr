# frozen_string_literal: true

describe VirusScannerJob, type: :job do
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
  end

  subject do
    VirusScannerJob.perform_now(blob)
  end

  context "when the virus scan launch before rails analyze" do
    before do
      allow(ClamavService).to receive(:safe_file?).and_return(true)
      subject
      blob.analyze
    end
    it do
      expect(blob.virus_scanner.safe?).to be_truthy
      expect(blob.analyzed?).to be_truthy
    end
  end

  context "when there is an integrity error" do
    before do
      blob.update_column('checksum', 'integrity error')

      assert_performed_jobs(5) do
        VirusScannerJob.perform_later(blob)
      end
    end

    it do
      expect(blob.reload.virus_scanner.corrupt?).to be_truthy
    end
  end

  context "when no virus is found" do
    before do
      allow(ClamavService).to receive(:safe_file?).and_return(true)
      subject
    end

    it { expect(blob.virus_scanner.safe?).to be_truthy }
  end

  context "when a virus is found" do
    before do
      allow(ClamavService).to receive(:safe_file?).and_return(false)
      subject
    end

    it { expect(blob.virus_scanner.infected?).to be_truthy }
  end

  context "when the blob has been deleted" do
    before do
      ActiveStorage::Blob.find(blob.id).purge # allowed in spec
    end

    it "ignores the error" do
      expect { subject }.not_to raise_error
    end
  end
end
