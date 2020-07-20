RSpec.describe VirusScannerJob, type: :job do
  include ActiveJob::TestHelper

  let(:champ) do
    champ = create(:champ_piece_justificative)
    champ.piece_justificative_file.attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
    champ.save
    champ
  end

  subject do
    perform_enqueued_jobs do
      VirusScannerJob.perform_later(champ.piece_justificative_file.blob)
    end
  end

  context "when no virus is found" do
    let(:virus_found?) { true }

    before do
      allow(ClamavService).to receive(:safe_file?).and_return(virus_found?)
      subject
    end

    it { expect(champ.reload.piece_justificative_file.virus_scanner.safe?).to be_truthy }
  end

  context "when a virus is found" do
    let(:virus_found?) { false }

    before do
      allow(ClamavService).to receive(:safe_file?).and_return(virus_found?)
      subject
    end

    it { expect(champ.reload.piece_justificative_file.virus_scanner.infected?).to be_truthy }
  end

  context "when the blob has been deleted" do
    before do
      Champ.find(champ.id).piece_justificative_file.purge
    end

    it "ignores the error" do
      expect { subject }.not_to raise_error
    end
  end
end
