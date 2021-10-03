describe Dossier do
  include ActiveJob::TestHelper

  before { Timecop.freeze(Time.zone.now) }
  after { Timecop.return }

  let(:archive) { create(:archive) }

  describe 'scopes' do
    describe 'staled' do
      let(:recent_archive) { create(:archive) }
      let(:staled_archive) { create(:archive, updated_at: (Archive::RETENTION_DURATION + 2).days.ago) }

      subject do
        archive; recent_archive; staled_archive
        Archive.stale
      end

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

  describe "#archives_by_period" do
    let(:groupe_instructeurs) { create(:groupe_instructeur) }
    let(:procedure) { create(:procedure, :published, groupe_instructeurs: [groupe_instructeurs]) }
    let(:month) { parse("2021-04-01") }

    before do
      create_dossier_for_day(procedure, 2021, 7, 2)
      create_dossier_for_day(procedure, 2021, 7, 2)
      create_dossier_for_day(procedure, 2021, 7, 2)
      create_dossier_for_day(procedure, 2021, 6, 2)
      create_dossier_for_day(procedure, 2021, 6, 2)
      create_dossier_for_day(procedure, 2021, 5, 31)
      create_dossier_for_day(procedure, 2021, 5, 30)
      create_dossier_for_day(procedure, 2021, 5, 29)
      create_dossier_for_day(procedure, 2021, 5, 28)
      create_dossier_for_day(procedure, 2021, 5, 27)
      create_dossier_for_day(procedure, 2021, 5, 27)
      create_dossier_for_day(procedure, 2021, 5, 26)
      create_dossier_for_day(procedure, 2021, 5, 26)
      create_dossier_for_day(procedure, 2021, 4, 2)
      create_dossier_for_day(procedure, 2021, 4, 3)
      create_dossier_for_day(procedure, 2021, 4, 4)
      create_dossier_for_day(procedure, 2021, 4, 5)

      allow_any_instance_of(Procedure).to receive(:average_dossier_weight).and_return(1.gigabyte)
    end

    subject { groupe_instructeurs.archives_by_period }

    it 'returns for each period matching archive if already created, nil otherwise' do
      instructeur = create(:instructeur)
      groupe_instructeurs.instructeurs << instructeur
      ProcedureArchiveService.new(procedure).create_pending_archive(instructeur, 'monthly', { month: parse('2021-07-01') })
      ProcedureArchiveService.new(procedure).create_pending_archive(instructeur, 'custom', { start_day: parse('2021-05-31'), end_day: parse('2021-05-28') })
      result = Archive.by_period(procedure, groupe_instructeurs)
      expect(result[0][:month]).to eq parse('2021-07-01')
      expect(result[0][:matching_archive].month).to eq parse('2021-07-01')
      expect(result[0][:count]).to eq 3

      expect(result[1][:month]).to eq parse('2021-06-01')
      expect(result[1][:matching_archive]).to eq nil
      expect(result[1][:count]).to eq 2

      expect(result[2][:count]).to eq 4
      expect(result[2][:matching_archive].time_span_type).to eq 'custom'
      expect(result[2][:matching_archive].start_day).to eq parse('2021-05-31')
      expect(result[2][:matching_archive].end_day).to eq parse('2021-05-28')
    end
  end

  private

  def parse(date)
    Time.find_zone("UTC").parse(date)
  end

  def create_dossier_for_day(procedure, year, month, day)
    Timecop.freeze(Time.find_zone("UTC").local(year, month, day)) do
      create(:dossier, :accepte, :with_attestation, procedure: procedure)
    end
  end
end
