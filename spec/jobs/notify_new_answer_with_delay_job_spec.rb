describe NotifyNewAnswerWithDelayJob, type: :job do
  let(:dossier) { double }
  let(:body) { "bim un body" }

  context 'when commentaire not soft_deleted?' do
    let(:commentaire) { create(:commentaire) }

    it 'call DossierMailer.notify_new_answer' do
      expect(DossierMailer).to receive(:notify_new_answer).with(dossier, body).and_return(double(deliver_now: true))
      NotifyNewAnswerWithDelayJob.perform_now(dossier, body, commentaire)
    end
  end

  context 'when commentaire is soft_deleted?' do
    let(:commentaire) { create(:commentaire, deleted_at: 2.hours.ago) }

    it 'skips DossierMailer.notify_new_anser' do
      expect(DossierMailer).not_to receive(:notify_new_answer).with(dossier, body)
      NotifyNewAnswerWithDelayJob.perform_now(dossier, body, commentaire)
    end
  end
end
