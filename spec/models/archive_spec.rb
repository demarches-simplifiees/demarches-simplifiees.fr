describe Dossier do
  include ActiveJob::TestHelper

  before { Timecop.freeze(Time.zone.now) }
  after { Timecop.return }

  let(:archive) { create(:archive) }

  describe 'scopes' do
    describe 'staled' do
      let(:recent_archive) { create(:archive) }
      let(:staled_archive) { create(:archive, updated_at: (Archive::MAX_DUREE_CONSERVATION_ARCHIVE + 2).days.ago) }

      subject { Archive.stale }

      it { is_expected.to match_array([staled_archive]) }
    end
  end

  describe '.status' do
    it { expect(archive.status).to eq('pending') }
  end

  describe '#make_available!' do
    before { archive.make_available! }
    it { expect(archive.status).to eq('generated') }
  end

  describe '#available?' do
    subject { archive.available? }
    context 'without attachment' do
      let(:archive) { create(:archive, file: nil) }
      it { is_expected.to eq(false) }
    end

    context 'with an attachment' do
      context 'when the attachment was created but the process was not over' do
        let(:archive) { create(:archive, :pending, file: Rack::Test::UploadedFile.new('spec/fixtures/files/file.pdf', 'application/pdf')) }
        it { is_expected.to eq(false) }
      end

      context 'when the attachment was created but the process was not over' do
        let(:archive) { create(:archive, :generated, file: Rack::Test::UploadedFile.new('spec/fixtures/files/file.pdf', 'application/pdf')) }
        it { is_expected.to eq(true) }
      end
    end
  end
end
