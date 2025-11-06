# frozen_string_literal: true

describe DossierPendingResponseConcern do
  describe '#pending_response?' do
    let(:dossier) { create(:dossier, :en_construction) }

    context 'when dossier has no pending response' do
      it { expect(dossier.pending_response?).to be_falsey }
    end

    context 'when dossier has a pending response' do
      before { create(:dossier_pending_response, dossier: dossier) }

      it { expect(dossier.pending_response?).to be_truthy }
    end

    context 'when dossier has a responded response' do
      before { create(:dossier_pending_response, :responded, dossier: dossier) }

      it { expect(dossier.pending_response?).to be_falsey }
    end
  end

  describe '#flag_as_pending_response!' do
    let(:procedure) { create(:procedure) }
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
    let(:instructeur) { create(:instructeur) }
    let(:commentaire) { create(:commentaire, dossier: dossier, instructeur: instructeur) }

    before do
      instructeur.groupe_instructeurs << dossier.groupe_instructeur
      create(:instructeurs_procedure, instructeur: instructeur, procedure: procedure, display_attente_reponse_notifications: 'all')
    end

    subject(:flag) { dossier.flag_as_pending_response!(commentaire) }

    it 'creates a pending response' do
      expect { flag }.to change { dossier.pending_responses.pending.count }.by(1)
    end

    it 'creates a pending response linked to the commentaire' do
      flag
      expect(dossier.pending_responses.last.commentaire).to eq(commentaire)
    end

    it 'creates an attente_reponse notification' do
      expect { flag }.to change { DossierNotification.where(dossier: dossier, notification_type: :attente_reponse).count }.by(1)
    end

    context 'when dossier already has a pending response' do
      before { create(:dossier_pending_response, dossier: dossier) }

      it 'does not create a new pending response' do
        expect { flag }.not_to change { dossier.pending_responses.pending.count }
      end
    end

    context 'when dossier has a responded response' do
      before { create(:dossier_pending_response, :responded, dossier: dossier) }

      it 'creates a new pending response' do
        expect { flag }.to change { dossier.pending_responses.pending.count }.by(1)
      end
    end
  end

  describe '#resolve_pending_response!' do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:instructeur) { create(:instructeur) }

    subject(:resolve) { dossier.resolve_pending_response! }

    context 'when dossier has no pending response' do
      it { expect { resolve }.not_to change { dossier.pending_responses.pending.count } }
    end

    context 'when dossier has a pending response' do
      let!(:pending_response) { create(:dossier_pending_response, dossier: dossier) }

      it 'marks the response as responded' do
        expect { resolve }.to change { pending_response.reload.responded_at }.from(nil)
      end
    end

    context 'when dossier has attente_reponse notification' do
      let!(:pending_response) { create(:dossier_pending_response, dossier: dossier) }
      let!(:notification) { create(:dossier_notification, dossier: dossier, instructeur: instructeur, notification_type: :attente_reponse) }

      it 'destroys notification' do
        expect { resolve }.to change { DossierNotification.where(dossier: dossier, notification_type: :attente_reponse).count }.to(0)
      end
    end
  end
end
