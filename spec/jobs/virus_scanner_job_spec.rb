describe VirusScannerJob, type: :job do
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
  end

  subject do
    VirusScannerJob.perform_now(blob)
  end

  context "when the blob is not analyzed yet" do
    it "retries the job later" do
      expect { subject }.to have_enqueued_job(VirusScannerJob)
    end
  end

  context "when the blob has been analyzed" do
    before do
      blob.analyze
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
        ActiveStorage::Blob.find(blob.id).purge
      end

      it "ignores the error" do
        expect { subject }.not_to raise_error
      end
    end
  end
end
