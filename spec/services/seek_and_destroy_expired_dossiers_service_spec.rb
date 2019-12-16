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

  describe '.dossier_en_construction' do
    let!(:state) { nil }
    let!(:today) { Time.zone.now.at_midnight }
    let!(:administrateur) { create(:administrateur) }
    let!(:date_near_expiring) { Date.today - procedure.duree_conservation_dossiers_dans_ds.months + 1.month }
    let!(:date_close_to_expiration) { Date.today - procedure.duree_conservation_dossiers_dans_ds.months - 6.days }
    let!(:date_not_expired) { Date.today - procedure.duree_conservation_dossiers_dans_ds.months + 2.months }
    let!(:procedure) { create(:procedure, :with_instructeur, declarative_with_state: state, administrateur: administrateur) }

    context "Suppression automatique des dossiers : " do
      let!(:expired_en_construction) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure, en_construction_at: date_close_to_expiration) } # expiré
      let!(:en_construction_close_to_expiration) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure, en_construction_at: date_near_expiring) } # expirant
      let!(:en_construction_close_but_with_notice_sent) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure, en_construction_at: date_near_expiring, en_construction_close_to_expiration_notice_sent_at: Time.zone.now) } # expirant mais mail déja envoyé
      let!(:en_construction_close_but_with_notice_sent2) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure, en_construction_at: date_near_expiring, en_construction_close_to_expiration_notice_sent_at: today - (Dossier::DRAFT_EXPIRATION + 1.day)) } # expirant mais mail déja envoyé depuis longtemp
      let!(:valid_en_construction) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure, en_construction_at: date_not_expired) } # autre

      before do
        allow(DossierMailer).to receive(:notify_en_construction_near_deletion).and_return(double(deliver_later: nil))
        allow(DossierMailer).to receive(:notify_excuse_deletion_to_user).and_return(double(deliver_later: nil))
        allow(DossierMailer).to receive(:notify_deletion).and_return(double(deliver_later: nil))

        SeekAndDestroyExpiredDossiersService.action_dossier_en_constuction
      end

      it 'Verification de la presence des dossiers non expirés' do
        expired_en_construction.reload
        en_construction_close_to_expiration.reload
        en_construction_close_but_with_notice_sent.reload
        valid_en_construction.reload
      end

      it 'Verification de la suppression des dossiers expirés' do
        expect { en_construction_close_but_with_notice_sent2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'verification de la creation de mail' do
        expect(DossierMailer).to have_received(:notify_excuse_deletion_to_user).once
        expect(DossierMailer).to have_received(:notify_excuse_deletion_to_user).with(en_construction_close_but_with_notice_sent2.user, [en_construction_close_but_with_notice_sent2.hash_for_deletion_mail])

        expect(DossierMailer).to have_received(:notify_deletion).once
        expect(DossierMailer).to have_received(:notify_deletion).with(administrateur, [en_construction_close_but_with_notice_sent2].map(&:hash_for_deletion_mail))

        expect(DossierMailer).to have_received(:notify_en_construction_near_deletion).thrice
        expect(DossierMailer).to have_received(:notify_en_construction_near_deletion).with(en_construction_close_to_expiration.user, [en_construction_close_to_expiration], true)
        expect(DossierMailer).to have_received(:notify_en_construction_near_deletion).with(expired_en_construction.user, [expired_en_construction], true)
        expect(DossierMailer).to have_received(:notify_en_construction_near_deletion).with(administrateur, [en_construction_close_to_expiration, expired_en_construction], false)
      end

      it 'verification de l enregistrement de l envois du mail' do
        expired_en_construction.reload
        expect(expired_en_construction.en_construction_close_to_expiration_notice_sent_at).not_to be_nil

        en_construction_close_to_expiration.reload
        expect(en_construction_close_to_expiration.en_construction_close_to_expiration_notice_sent_at).not_to be_nil
      end
    end

    after { Timecop.return }
  end
end
