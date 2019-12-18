require 'spec_helper'

describe SeekAndDestroyExpiredDossiersService do
  describe '.dossier_brouillon' do
    let!(:today) { Time.zone.now.at_midnight }
    let!(:procedure) { create(:procedure, duree_conservation_dossiers_dans_ds: 6) }
    let!(:date_close_to_expiration) { Date.today - procedure.duree_conservation_dossiers_dans_ds.months + 1.month }
    let!(:date_expired) { Date.today - procedure.duree_conservation_dossiers_dans_ds.months - 6.days }
    let!(:date_not_expired) { Date.today - procedure.duree_conservation_dossiers_dans_ds.months + 2.months }

    context "Envoi de message pour les dossiers expirant dans - d'un mois" do
      let!(:expired_brouillon) { create(:dossier, procedure: procedure, created_at: date_expired, brouillon_close_to_expiration_notice_sent_at: today - (Dossier::DRAFT_EXPIRATION + 1.day)) }
      let!(:brouillon_close_to_expiration) { create(:dossier, procedure: procedure, created_at: date_close_to_expiration) }
      let!(:brouillon_close_but_with_notice_sent) { create(:dossier, procedure: procedure, created_at: date_close_to_expiration, brouillon_close_to_expiration_notice_sent_at: Time.zone.now) }
      let!(:valid_brouillon) { create(:dossier, procedure: procedure, created_at: date_not_expired) }

      before do
        allow(DossierMailer).to receive(:notify_brouillon_near_deletion).and_return(double(deliver_later: nil))
        allow(DossierMailer).to receive(:notify_brouillon_deletion).and_return(double(deliver_later: nil))
        SeekAndDestroyExpiredDossiersService.action_dossier_brouillon
      end

      it 'verification de la creation de mail' do
        expect(DossierMailer).to have_received(:notify_brouillon_near_deletion).once
        expect(DossierMailer).to have_received(:notify_brouillon_near_deletion).with(brouillon_close_to_expiration.user, [brouillon_close_to_expiration])
      end

      it 'Verification du changement d etat du champ' do
        expect(brouillon_close_to_expiration.reload.brouillon_close_to_expiration_notice_sent_at).not_to be_nil
      end

      it 'notifies deletion' do
        expect(DossierMailer).to have_received(:notify_brouillon_deletion).once
        expect(DossierMailer).to have_received(:notify_brouillon_deletion).with(expired_brouillon.user, [expired_brouillon.hash_for_deletion_mail])
      end

      it 'deletes the expired brouillon' do
        expect(DeletedDossier.find_by(dossier_id: expired_brouillon.id)).to be_present
        expect { expired_brouillon.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
