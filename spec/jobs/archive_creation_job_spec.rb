describe ArchiveCreationJob, type: :job do
  describe 'perform' do
    let(:archive) { create(:archive, status: status, groupe_instructeurs: [procedure.groupe_instructeurs.first]) }
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure, instructeurs: [instructeur]) }
    let(:job) { ArchiveCreationJob.new(procedure, archive, instructeur) }

    context 'when it fails' do
      let(:status) { :pending }
      let(:mailer) { double('mailer', deliver_later: true) }
      before { expect(UserMailer).not_to receive(:send_archive) }

      it 'does not send email and forward error for retry' do
        allow(DownloadableFileService).to receive(:download_and_zip).and_raise(StandardError, "kaboom")
        expect { job.perform_now }.to raise_error(StandardError, "kaboom")
        expect(archive.reload.failed?).to eq(true)
      end
    end

    context 'when it works' do
      let(:mailer) { double('mailer', deliver_later: true) }
      before do
        allow(DownloadableFileService).to receive(:download_and_zip).and_return(true)
        expect(UserMailer).to receive(:send_archive).and_return(mailer)
      end

      context 'when archive failed previously' do
        let(:status) { :failed }
        it 'restarts and works from failed states' do
          expect { job.perform_now }.to change { archive.reload.failed? }.from(true).to(false)
        end
      end
      context 'when archive start from pending state' do
        let(:status) { :pending }
        it 'restarts and works from failed states' do
          expect { job.perform_now }.to change { archive.reload.generated? }.from(false).to(true)
        end
      end
    end
  end
end
