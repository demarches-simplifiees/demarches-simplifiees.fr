RSpec.describe VirusScannerJob, type: :job do
  let(:champ) do
    champ = create(:champ, :piece_justificative)
    champ.piece_justificative_file.attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
    champ
  end

  subject { VirusScannerJob.new.perform(champ.piece_justificative_file.blob) }

  context "when no virus is found" do
    let(:virus_found?) { true }

    before do
      allow(ClamavService).to receive(:safe_file?).and_return(virus_found?)
      subject
    end

    it { expect(champ.piece_justificative_file.virus_scanner.safe?).to be_truthy }
  end

  context "when a virus is found" do
    let(:virus_found?) { false }

    before do
      allow(ClamavService).to receive(:safe_file?).and_return(virus_found?)
      subject
    end

    it { expect(champ.piece_justificative_file.virus_scanner.infected?).to be_truthy }
  end
end
