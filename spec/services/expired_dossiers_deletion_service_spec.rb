require 'spec_helper'

describe ExpiredDossiersDeletionService do
  describe '#process_expired_dossiers_brouillon' do
    let(:draft_expiration) { 1.month + 5.days }
    let!(:today) { Time.zone.now.at_midnight }
    let!(:procedure) { create(:procedure, duree_conservation_dossiers_dans_ds: 6) }
    let!(:date_close_to_expiration) { Date.today - procedure.duree_conservation_dossiers_dans_ds.months + 1.month }
    let!(:date_expired) { Date.today - procedure.duree_conservation_dossiers_dans_ds.months - 6.days }
    let!(:date_not_expired) { Date.today - procedure.duree_conservation_dossiers_dans_ds.months + 2.months }

    context 'send messages for dossiers expiring soon and delete expired' do
      let!(:expired_brouillon) { create(:dossier, procedure: procedure, created_at: date_expired, brouillon_close_to_expiration_notice_sent_at: today - (draft_expiration + 1.day)) }
      let!(:brouillon_close_to_expiration) { create(:dossier, procedure: procedure, created_at: date_close_to_expiration) }
      let!(:brouillon_close_but_with_notice_sent) { create(:dossier, procedure: procedure, created_at: date_close_to_expiration, brouillon_close_to_expiration_notice_sent_at: Time.zone.now) }
      let!(:valid_brouillon) { create(:dossier, procedure: procedure, created_at: date_not_expired) }

      before do
        allow(DossierMailer).to receive(:notify_brouillon_near_deletion).and_return(double(deliver_later: nil))
        allow(DossierMailer).to receive(:notify_brouillon_deletion).and_return(double(deliver_later: nil))

        ExpiredDossiersDeletionService.process_expired_dossiers_brouillon
      end

      it 'emails should be sent' do
        expect(DossierMailer).to have_received(:notify_brouillon_near_deletion).once
        expect(DossierMailer).to have_received(:notify_brouillon_near_deletion).with(brouillon_close_to_expiration.user, [brouillon_close_to_expiration])
      end

      it 'dossier state should change' do
        expect(brouillon_close_to_expiration.reload.brouillon_close_to_expiration_notice_sent_at).not_to be_nil
      end

      it 'deletes and notify expired brouillon' do
        expect(DossierMailer).to have_received(:notify_brouillon_deletion).once
        expect(DossierMailer).to have_received(:notify_brouillon_deletion).with(expired_brouillon.user, [expired_brouillon.hash_for_deletion_mail])

        expect(DeletedDossier.find_by(dossier_id: expired_brouillon.id)).to be_present
        expect { expired_brouillon.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
