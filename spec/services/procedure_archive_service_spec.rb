describe ProcedureArchiveService do
  describe '#create_archive' do
    let(:procedure) { create(:procedure, :published) }
    let(:instructeur) { create(:instructeur) }
    let(:service) { ProcedureArchiveService.new(procedure) }
    let(:year) { 2020 }
    let(:month) { 3 }
    let(:date_month) { Date.strptime("#{year}-#{month}", "%Y-%m") }

    before do
      create_dossier_for_month(year, month)
      create_dossier_for_month(2020, month)
    end

    after { Timecop.return }

    context 'for a specific month' do
      let(:year) { 2021 }
      let(:mailer) { double('mailer', deliver_later: true) }

      it 'creates a monthly archive' do
        expect(InstructeurMailer).to receive(:send_archive).and_return(mailer)

        service.create_archive(instructeur, 'monthly', date_month)

        archive = Archive.last
        archive.file.open do |f|
          files = ZipTricks::FileReader.read_zip_structure(io: f)
          expect(files.size).to be 2
          expect(files.first.filename).to include("export")
          expect(files.last.filename).to include("attestation")
        end
        expect(archive.content_type).to eq 'monthly'
        expect(archive.file.attached?).to be_truthy
      end
    end

    context 'for all months' do
      let(:mailer) { double('mailer', deliver_later: true) }

      it 'creates a everything archive' do
        expect(InstructeurMailer).to receive(:send_archive).and_return(mailer)

        service.create_archive(instructeur, 'everything')

        archive = Archive.last
        archive.file.open do |f|
          files = ZipTricks::FileReader.read_zip_structure(io: f)
          expect(files.size).to be 4
        end
        expect(archive.content_type).to eq 'everything'
        expect(archive.file.attached?).to be_truthy
      end
    end
  end

  private

  def create_dossier_for_month(year, month)
    Timecop.freeze(Time.zone.local(year, month, 5))
    create(:dossier, :accepte, :with_attestation, procedure: procedure)
  end
end
