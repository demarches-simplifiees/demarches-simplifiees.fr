# frozen_string_literal: true

describe Archive do
  include ActiveJob::TestHelper

  before { freeze_time }

  let!(:archive) { create(:archive, job_status: :pending) }

  describe 'scopes' do
    describe 'staled' do
      let!(:recent_archive) { create(:archive, job_status: :pending) }
      let!(:staled_archive_still_pending) { create(:archive, job_status: :pending, updated_at: (Archive::RETENTION_DURATION + 2).days.ago) }
      let!(:staled_archive_still_failed) { create(:archive, job_status: :failed, updated_at: (Archive::RETENTION_DURATION + 2).days.ago) }
      let!(:staled_archive_still_generated) { create(:archive, job_status: :generated, updated_at: (Archive::RETENTION_DURATION + 2).days.ago) }

      subject do
        Archive.stale(Archive::RETENTION_DURATION)
      end

      it { is_expected.to match_array([staled_archive_still_failed, staled_archive_still_generated]) }
    end

    describe 'stuck' do
      let!(:recent_archive) { create(:archive, job_status: :pending) }
      let!(:staled_archive_still_pending) { create(:archive, job_status: :pending, updated_at: (Archive::MAX_DUREE_GENERATION + 2).days.ago) }
      let!(:staled_archive_still_failed) { create(:archive, job_status: :failed, updated_at: (Archive::MAX_DUREE_GENERATION + 2).days.ago) }
      let!(:staled_archive_still_generated) { create(:archive, job_status: :generated, updated_at: (Archive::MAX_DUREE_GENERATION + 2).days.ago) }

      subject do
        Archive.stuck(Archive::MAX_DUREE_GENERATION)
      end

      it { is_expected.to match_array([staled_archive_still_pending]) }
    end
  end

  describe '.job_status' do
    it { expect(archive.job_status).to eq('pending') }
  end

  describe '#make_available!' do
    before { archive.make_available! }
    it { expect(archive.job_status).to eq('generated') }
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
