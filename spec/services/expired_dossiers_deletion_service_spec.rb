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

  describe '#delete_expired_en_construction_and_notify' do
    let!(:warning_period) { 1.month + 5.days }

    before { Timecop.freeze(Time.zone.now) }
    after  { Timecop.return }

    before do
      allow(DossierMailer).to receive(:notify_automatic_deletion_to_user).and_return(double(deliver_later: nil))
      allow(DossierMailer).to receive(:notify_automatic_deletion_to_administration).and_return(double(deliver_later: nil))
    end

    context 'with a single dossier' do
      let!(:dossier) { create(:dossier, :en_construction, :followed, en_construction_close_to_expiration_notice_sent_at: notice_sent_at) }

      before { ExpiredDossiersDeletionService.delete_expired_en_construction_and_notify }

      context 'when no notice has been sent' do
        let(:notice_sent_at) { nil }

        it { expect { dossier.reload }.not_to raise_error }
        it { expect(DossierMailer).not_to have_received(:notify_automatic_deletion_to_user) }
        it { expect(DossierMailer).not_to have_received(:notify_automatic_deletion_to_administration) }
      end

      context 'when a notice has been sent not so long ago' do
        let(:notice_sent_at) { (warning_period - 1.day).ago }

        it { expect { dossier.reload }.not_to raise_error }
        it { expect(DossierMailer).not_to have_received(:notify_automatic_deletion_to_user) }
        it { expect(DossierMailer).not_to have_received(:notify_automatic_deletion_to_administration) }
      end

      context 'when a notice has been sent a long time ago' do
        let(:notice_sent_at) { (warning_period + 1.day).ago }

        it { expect { dossier.reload }.to raise_error(ActiveRecord::RecordNotFound) }

        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).once }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).with(dossier.user.email, [dossier.hash_for_deletion_mail]) }

        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).twice }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with(dossier.procedure.administrateurs.first.email, [dossier.hash_for_deletion_mail]) }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with(dossier.followers_instructeurs.first.email, [dossier.hash_for_deletion_mail]) }
      end
    end

    context 'with 2 dossiers to delete' do
      let!(:user) { create(:user) }
      let!(:dossier_1) { create(:dossier, :en_construction, user: user, en_construction_close_to_expiration_notice_sent_at: (warning_period + 1.day).ago) }
      let!(:dossier_2) { create(:dossier, :en_construction, user: user, en_construction_close_to_expiration_notice_sent_at: (warning_period + 1.day).ago) }

      let!(:instructeur) { create(:instructeur) }

      before do
        instructeur.followed_dossiers << dossier_1 << dossier_2
        ExpiredDossiersDeletionService.delete_expired_en_construction_and_notify
      end

      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).once }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).with(user.email, match_array([dossier_1, dossier_2].map(&:hash_for_deletion_mail))) }

      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).thrice }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with(instructeur.email, match_array([dossier_1, dossier_2].map(&:hash_for_deletion_mail))) }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with(dossier_1.procedure.administrateurs.first.email, [dossier_1.hash_for_deletion_mail]) }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with(dossier_2.procedure.administrateurs.first.email, [dossier_2.hash_for_deletion_mail]) }
    end
  end

  describe '#process_expired_dossiers_en_constuction' do
    let(:draft_expiration) { 1.month + 5.days }
    let!(:today) { Time.zone.now.at_midnight }
    let!(:administrateur) { create(:administrateur) }
    let!(:procedure1) { create(:procedure, :with_instructeur, duree_conservation_dossiers_dans_ds: 6, administrateur: administrateur) }
    let!(:date_near_expiring) { Date.today - procedure1.duree_conservation_dossiers_dans_ds.months + 1.month }
    let!(:date_close_to_expiration) { Date.today - procedure1.duree_conservation_dossiers_dans_ds.months - 6.days }
    let!(:date_not_expired) { Date.today - procedure1.duree_conservation_dossiers_dans_ds.months + 2.months }

    context 'send messages for dossiers expiring soon and delete expired' do
      let!(:expired_en_construction) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure1, en_construction_at: date_close_to_expiration) }
      let!(:en_construction_close_to_expiration) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure1, en_construction_at: date_near_expiring) }
      let!(:en_construction_close_but_with_notice_sent) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure1, en_construction_at: date_near_expiring, en_construction_close_to_expiration_notice_sent_at: Time.zone.now) }
      let!(:en_construction_close_but_with_notice_sent2) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure1, en_construction_at: date_near_expiring, en_construction_close_to_expiration_notice_sent_at: today - (draft_expiration + 1.day)) }
      let!(:valid_en_construction) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure1, en_construction_at: date_not_expired) }

      before do
        allow(DossierMailer).to receive(:notify_en_construction_near_deletion).and_return(double(deliver_later: nil))
        allow(DossierMailer).to receive(:notify_deletion_to_administration).and_return(double(deliver_later: nil))
        allow(DossierMailer).to receive(:notify_deletion_to_user).and_return(double(deliver_later: nil))

        ExpiredDossiersDeletionService.process_expired_dossiers_en_construction
      end

      it 'not expired dossiers should reload' do
        expired_en_construction.reload
        en_construction_close_to_expiration.reload
        en_construction_close_but_with_notice_sent.reload
        valid_en_construction.reload
      end

      it 'expired dossier should be deleted' do
        expect { en_construction_close_but_with_notice_sent2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'emails should be sent' do
        expect(DossierMailer).to have_received(:notify_deletion_to_user).once
        expect(DossierMailer).to have_received(:notify_deletion_to_user).with(en_construction_close_but_with_notice_sent2.user, [en_construction_close_but_with_notice_sent2.hash_for_deletion_mail])

        expect(DossierMailer).to have_received(:notify_deletion_to_administration).once
        expect(DossierMailer).to have_received(:notify_deletion_to_administration).with(administrateur, [en_construction_close_but_with_notice_sent2].map(&:hash_for_deletion_mail))

        expect(DossierMailer).to have_received(:notify_en_construction_near_deletion).thrice
        expect(DossierMailer).to have_received(:notify_en_construction_near_deletion).with(en_construction_close_to_expiration.user, [en_construction_close_to_expiration], true)
        expect(DossierMailer).to have_received(:notify_en_construction_near_deletion).with(expired_en_construction.user, [expired_en_construction], true)
      end

      it 'dossiers soon to expire should be marked' do
        expired_en_construction.reload
        expect(expired_en_construction.en_construction_close_to_expiration_notice_sent_at).not_to be_nil

        en_construction_close_to_expiration.reload
        expect(en_construction_close_to_expiration.en_construction_close_to_expiration_notice_sent_at).not_to be_nil
      end
    end
  end
end
