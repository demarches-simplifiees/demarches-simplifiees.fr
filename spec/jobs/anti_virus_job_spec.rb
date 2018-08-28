RSpec.describe AntiVirusJob, type: :job do
  let(:champ) do
    champ = create(:champ, :piece_justificative)
    champ.piece_justificative_file.attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
    champ
  end
  let(:virus_scan) { create(:virus_scan, status: VirusScan.statuses.fetch(:pending), champ: champ, blob_key: champ.piece_justificative_file.blob.key) }

  subject { AntiVirusJob.new.perform(virus_scan) }

  context "when no virus is found" do
    let(:virus_found?) { true }

    before do
      allow(ClamavService).to receive(:safe_file?).and_return(virus_found?)
      subject
    end

    it { expect(virus_scan.reload.status).to eq(VirusScan.statuses.fetch(:safe)) }
  end

  context "when a virus is found" do
    let(:virus_found?) { false }

    before do
      allow(ClamavService).to receive(:safe_file?).and_return(virus_found?)
      subject
    end

    it { expect(virus_scan.reload.status).to eq(VirusScan.statuses.fetch(:infected)) }
  end
end
