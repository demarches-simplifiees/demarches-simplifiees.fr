# frozen_string_literal: true

describe DossierPendingResponse do
  let(:dossier) { create(:dossier, :en_construction) }
  let(:instructeur) { create(:instructeur) }
  let(:commentaire) { create(:commentaire, dossier: dossier, instructeur: instructeur) }

  describe '#pending?' do
    context 'when responded_at is nil' do
      let(:pending_response) { create(:dossier_pending_response, dossier: dossier, commentaire: commentaire) }

      it { expect(pending_response.pending?).to be_truthy }
    end

    context 'when responded_at is present' do
      let(:pending_response) { create(:dossier_pending_response, dossier: dossier, commentaire: commentaire, responded_at: Time.current) }

      it { expect(pending_response.pending?).to be_falsey }
    end
  end

  describe '#responded?' do
    context 'when responded_at is nil' do
      let(:pending_response) { create(:dossier_pending_response, dossier: dossier, commentaire: commentaire) }

      it { expect(pending_response.responded?).to be_falsey }
    end

    context 'when responded_at is present' do
      let(:pending_response) { create(:dossier_pending_response, dossier: dossier, commentaire: commentaire, responded_at: Time.current) }

      it { expect(pending_response.responded?).to be_truthy }
    end
  end

  describe '#respond!' do
    let(:pending_response) { create(:dossier_pending_response, dossier: dossier, commentaire: commentaire) }
    let!(:notification) { create(:dossier_notification, dossier: dossier, instructeur: instructeur, notification_type: :attente_reponse) }

    it 'marks as responded' do
      expect { pending_response.respond! }.to change { pending_response.reload.responded_at }.from(nil)
    end

    it 'destroys attente_reponse notification' do
      expect { pending_response.respond! }.to change { DossierNotification.where(dossier: dossier, notification_type: :attente_reponse).count }.by(-1)
    end
  end
end
