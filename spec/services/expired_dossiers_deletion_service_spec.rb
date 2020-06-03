describe ExpiredDossiersDeletionService do
  let(:warning_period) { 1.month + 5.days }
  let(:conservation_par_defaut) { 3.months }
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published) }
  let(:procedure_2) { create(:procedure, :published) }
  let(:reference_date) { Date.parse("March 8") }

  describe '#process_expired_dossiers_brouillon' do
    let(:today) { Time.zone.now.at_midnight }
    let(:date_close_to_expiration) { Time.zone.now - procedure.duree_conservation_dossiers_dans_ds.months + 1.month }
    let(:date_expired) { Time.zone.now - procedure.duree_conservation_dossiers_dans_ds.months - 6.days }
    let(:date_not_expired) { Time.zone.now - procedure.duree_conservation_dossiers_dans_ds.months + 2.months }

    context 'send messages for dossiers expiring soon and delete expired' do
      let!(:expired_brouillon) { create(:dossier, procedure: procedure, created_at: date_expired, brouillon_close_to_expiration_notice_sent_at: today - (warning_period + 1.day)) }
      let!(:brouillon_close_to_expiration) { create(:dossier, procedure: procedure, created_at: date_close_to_expiration) }
      let!(:brouillon_close_but_with_notice_sent) { create(:dossier, procedure: procedure, created_at: date_close_to_expiration, brouillon_close_to_expiration_notice_sent_at: Time.zone.now) }
      let!(:valid_brouillon) { create(:dossier, procedure: procedure, created_at: date_not_expired) }

      before do
        allow(DossierMailer).to receive(:notify_brouillon_near_deletion).and_call_original
        allow(DossierMailer).to receive(:notify_brouillon_deletion).and_call_original

        ExpiredDossiersDeletionService.process_expired_dossiers_brouillon
      end

      it 'emails should be sent' do
        expect(DossierMailer).to have_received(:notify_brouillon_near_deletion).once
        expect(DossierMailer).to have_received(:notify_brouillon_near_deletion).with([brouillon_close_to_expiration], brouillon_close_to_expiration.user.email)
      end

      it 'dossier brouillon_close_to_expiration_notice_sent_at should change' do
        expect(brouillon_close_to_expiration.reload.brouillon_close_to_expiration_notice_sent_at).not_to be_nil
      end

      it 'deletes and notify expired brouillon' do
        expect(DossierMailer).to have_received(:notify_brouillon_deletion).once
        expect(DossierMailer).to have_received(:notify_brouillon_deletion).with([expired_brouillon.hash_for_deletion_mail], expired_brouillon.user.email)
        expect(DeletedDossier.find_by(dossier_id: expired_brouillon.id)).not_to be_present
        expect { expired_brouillon.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#send_brouillon_expiration_notices' do
    before { Timecop.freeze(reference_date) }
    after  { Timecop.return }

    before do
      allow(DossierMailer).to receive(:notify_brouillon_near_deletion).and_return(double(deliver_later: nil))
    end

    context 'with a single dossier' do
      let!(:dossier) { create(:dossier, procedure: procedure, created_at: created_at) }

      before { ExpiredDossiersDeletionService.send_brouillon_expiration_notices }

      context 'when the dossier is not closed to expiration' do
        let(:created_at) { (conservation_par_defaut - 1.month - 1.day).ago }

        it { expect(dossier.reload.brouillon_close_to_expiration_notice_sent_at).to be_nil }
        it { expect(DossierMailer).not_to have_received(:notify_brouillon_near_deletion) }
      end

      context 'when the dossier is closed to expiration' do
        let(:created_at) { (conservation_par_defaut - 1.month + 1.day).ago }

        it { expect(dossier.reload.brouillon_close_to_expiration_notice_sent_at).not_to be_nil }
        it { expect(DossierMailer).to have_received(:notify_brouillon_near_deletion).once }
        it { expect(DossierMailer).to have_received(:notify_brouillon_near_deletion).with([dossier], dossier.user.email) }
      end
    end

    context 'with 2 dossiers to notice' do
      let!(:dossier_1) { create(:dossier, procedure: procedure, user: user, created_at: (conservation_par_defaut - 1.month + 1.day).ago) }
      let!(:dossier_2) { create(:dossier, procedure: procedure_2, user: user, created_at: (conservation_par_defaut - 1.month + 1.day).ago) }

      before { ExpiredDossiersDeletionService.send_brouillon_expiration_notices }

      it { expect(DossierMailer).to have_received(:notify_brouillon_near_deletion).once }
      it { expect(DossierMailer).to have_received(:notify_brouillon_near_deletion).with(match_array([dossier_1, dossier_2]), user.email) }
    end
  end

  describe '#delete_expired_brouillons_and_notify' do
    before { Timecop.freeze(reference_date) }
    after  { Timecop.return }

    before do
      allow(DossierMailer).to receive(:notify_brouillon_deletion).and_return(double(deliver_later: nil))
    end

    context 'with a single dossier' do
      let!(:dossier) { create(:dossier, procedure: procedure, brouillon_close_to_expiration_notice_sent_at: notice_sent_at) }

      before { ExpiredDossiersDeletionService.delete_expired_brouillons_and_notify }

      context 'when no notice has been sent' do
        let(:notice_sent_at) { nil }

        it { expect { dossier.reload }.not_to raise_error }
        it { expect(DossierMailer).not_to have_received(:notify_brouillon_deletion) }
      end

      context 'when a notice has been sent not so long ago' do
        let(:notice_sent_at) { (warning_period - 4.days).ago }

        it { expect { dossier.reload }.not_to raise_error }
        it { expect(DossierMailer).not_to have_received(:notify_brouillon_deletion) }
      end

      context 'when a notice has been sent a long time ago' do
        let(:notice_sent_at) { (warning_period + 4.days).ago }

        it { expect { dossier.reload }.to raise_error(ActiveRecord::RecordNotFound) }

        it { expect(DossierMailer).to have_received(:notify_brouillon_deletion).once }
        it { expect(DossierMailer).to have_received(:notify_brouillon_deletion).with([dossier.hash_for_deletion_mail], dossier.user.email) }
      end
    end

    context 'with 2 dossiers to delete' do
      # warning_period + 2 days for Tahiti instead of 1 because (now - 1.month - 5 days) + 1.month + 5 days != now
      let!(:dossier_1) { create(:dossier, procedure: procedure, user: user, brouillon_close_to_expiration_notice_sent_at: (warning_period + 2.days).ago) }
      let!(:dossier_2) { create(:dossier, procedure: procedure_2, user: user, brouillon_close_to_expiration_notice_sent_at: (warning_period + 2.days).ago) }

      before { ExpiredDossiersDeletionService.delete_expired_brouillons_and_notify }

      it { expect(DossierMailer).to have_received(:notify_brouillon_deletion).once }
      it { expect(DossierMailer).to have_received(:notify_brouillon_deletion).with(match_array([dossier_1.hash_for_deletion_mail, dossier_2.hash_for_deletion_mail]), user.email) }
    end
  end

  describe '#send_en_construction_expiration_notices' do
    before { Timecop.freeze(reference_date) }
    after  { Timecop.return }

    before do
      allow(DossierMailer).to receive(:notify_near_deletion_to_user).and_return(double(deliver_later: nil))
      allow(DossierMailer).to receive(:notify_near_deletion_to_administration).and_return(double(deliver_later: nil))
    end

    context 'with a single dossier' do
      let!(:dossier) { create(:dossier, :en_construction, :followed, procedure: procedure, en_construction_at: en_construction_at) }

      before { ExpiredDossiersDeletionService.send_en_construction_expiration_notices }

      context 'when the dossier is not near deletion' do
        let(:en_construction_at) { (conservation_par_defaut - 1.month - 1.day).ago }

        it { expect(dossier.reload.en_construction_close_to_expiration_notice_sent_at).to be_nil }
        it { expect(DossierMailer).not_to have_received(:notify_near_deletion_to_user) }
        it { expect(DossierMailer).not_to have_received(:notify_near_deletion_to_administration) }
      end

      context 'when the dossier is near deletion' do
        let(:en_construction_at) { (conservation_par_defaut - 1.month + 1.day).ago }

        it { expect(dossier.reload.en_construction_close_to_expiration_notice_sent_at).not_to be_nil }

        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).once }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).twice }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).with([dossier], dossier.user.email) }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier], dossier.procedure.administrateurs.first.email) }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier], dossier.followers_instructeurs.first.email) }
      end
    end

    context 'with 2 dossiers to notice' do
      let!(:dossier_1) { create(:dossier, :en_construction, procedure: procedure, user: user, en_construction_at: (conservation_par_defaut - 1.month + 1.day).ago) }
      let!(:dossier_2) { create(:dossier, :en_construction, procedure: procedure_2, user: user, en_construction_at: (conservation_par_defaut - 1.month + 1.day).ago) }

      let!(:instructeur) { create(:instructeur) }

      before do
        instructeur.followed_dossiers << dossier_1 << dossier_2
        ExpiredDossiersDeletionService.send_en_construction_expiration_notices
      end

      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).once }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).exactly(3).times }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).with(match_array([dossier_1, dossier_2]), user.email) }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with(match_array([dossier_1, dossier_2]), instructeur.email) }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier_1], dossier_1.procedure.administrateurs.first.email) }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier_2], dossier_2.procedure.administrateurs.first.email) }
    end

    context 'when an instructeur is also administrateur' do
      let!(:administrateur) { procedure.administrateurs.first }
      let!(:dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: (conservation_par_defaut - 1.month + 1.day).ago) }

      before do
        administrateur.instructeur.followed_dossiers << dossier
        ExpiredDossiersDeletionService.send_en_construction_expiration_notices
      end

      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).once }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).with([dossier], dossier.user.email) }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier], administrateur.email) }
    end
  end

  describe '#delete_expired_en_construction_and_notify' do
    let!(:warning_period) { 1.month + 5.days }

    before { Timecop.freeze(reference_date) }
    after  { Timecop.return }

    before do
      allow(DossierMailer).to receive(:notify_automatic_deletion_to_user).and_call_original
      allow(DossierMailer).to receive(:notify_automatic_deletion_to_administration).and_call_original
    end

    context 'with a single dossier' do
      let!(:dossier) { create(:dossier, :en_construction, :followed, procedure: procedure, en_construction_close_to_expiration_notice_sent_at: notice_sent_at) }
      let(:deleted_dossier) { DeletedDossier.find_by(dossier_id: dossier.id) }

      before { ExpiredDossiersDeletionService.delete_expired_en_construction_and_notify }

      context 'when no notice has been sent' do
        let(:notice_sent_at) { nil }

        it { expect { dossier.reload }.not_to raise_error }
        it { expect(DossierMailer).not_to have_received(:notify_automatic_deletion_to_user) }
        it { expect(DossierMailer).not_to have_received(:notify_automatic_deletion_to_administration) }
      end

      context 'when a notice has been sent not so long ago' do
        let(:notice_sent_at) { (warning_period - 4.days).ago }

        it { expect { dossier.reload }.not_to raise_error }
        it { expect(DossierMailer).not_to have_received(:notify_automatic_deletion_to_user) }
        it { expect(DossierMailer).not_to have_received(:notify_automatic_deletion_to_administration) }
      end

      context 'when a notice has been sent a long time ago' do
        let(:notice_sent_at) { (warning_period + 4.days).ago }

        it { expect { dossier.reload }.to raise_error(ActiveRecord::RecordNotFound) }

        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).once }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).with([deleted_dossier], dossier.user.email) }

        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).twice }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([deleted_dossier], dossier.procedure.administrateurs.first.email) }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([deleted_dossier], dossier.followers_instructeurs.first.email) }
      end
    end

    context 'with 2 dossiers to delete' do
      # warning_period + 2 days for Tahiti instead of 1 because (now - 1.month - 5 days) + 1.month + 5 days != now
      let!(:dossier_1) { create(:dossier, :en_construction, procedure: procedure, user: user, en_construction_close_to_expiration_notice_sent_at: (warning_period + 2.days).ago) }
      let!(:dossier_2) { create(:dossier, :en_construction, procedure: procedure_2, user: user, en_construction_close_to_expiration_notice_sent_at: (warning_period + 2.days).ago) }
      let(:deleted_dossier_1) { DeletedDossier.find_by(dossier_id: dossier_1.id) }
      let(:deleted_dossier_2) { DeletedDossier.find_by(dossier_id: dossier_2.id) }

      let!(:instructeur) { create(:instructeur) }

      before do
        instructeur.followed_dossiers << dossier_1 << dossier_2
        ExpiredDossiersDeletionService.delete_expired_en_construction_and_notify
      end

      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).once }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).with(match_array([deleted_dossier_1, deleted_dossier_2]), user.email) }

      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).thrice }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with(match_array([deleted_dossier_1, deleted_dossier_2]), instructeur.email) }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([deleted_dossier_1], dossier_1.procedure.administrateurs.first.email) }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([deleted_dossier_2], dossier_2.procedure.administrateurs.first.email) }
    end
  end

  describe '#send_termine_expiration_notices' do
    before { Timecop.freeze(reference_date) }
    after  { Timecop.return }

    before do
      allow(DossierMailer).to receive(:notify_near_deletion_to_user).and_call_original
      allow(DossierMailer).to receive(:notify_near_deletion_to_administration).and_call_original
    end

    context 'with a single dossier' do
      let!(:dossier) { create(:dossier, :accepte, :followed, procedure: procedure, processed_at: processed_at) }

      before { ExpiredDossiersDeletionService.send_termine_expiration_notices }

      context 'when the dossier is not near deletion' do
        let(:processed_at) { (conservation_par_defaut - 1.month - 1.day).ago }

        it { expect(dossier.reload.termine_close_to_expiration_notice_sent_at).to be_nil }
        it { expect(DossierMailer).not_to have_received(:notify_near_deletion_to_user) }
        it { expect(DossierMailer).not_to have_received(:notify_near_deletion_to_administration) }
      end

      context 'when the dossier is near deletion' do
        let(:processed_at) { (conservation_par_defaut - 1.month + 1.day).ago }

        it { expect(dossier.reload.termine_close_to_expiration_notice_sent_at).not_to be_nil }

        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).once }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).twice }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).with([dossier], dossier.user.email) }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier], dossier.procedure.administrateurs.first.email) }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier], dossier.followers_instructeurs.first.email) }
      end
    end

    context 'with 2 dossiers to notice' do
      let!(:dossier_1) { create(:dossier, :accepte, procedure: procedure, user: user, processed_at: (conservation_par_defaut - 1.month + 1.day).ago) }
      let!(:dossier_2) { create(:dossier, :accepte, procedure: procedure_2, user: user, processed_at: (conservation_par_defaut - 1.month + 1.day).ago) }

      let!(:instructeur) { create(:instructeur) }

      before do
        instructeur.followed_dossiers << dossier_1 << dossier_2
        ExpiredDossiersDeletionService.send_termine_expiration_notices
      end

      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).once }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).exactly(3).times }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).with(match_array([dossier_1, dossier_2]), user.email) }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with(match_array([dossier_1, dossier_2]), instructeur.email) }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier_1], dossier_1.procedure.administrateurs.first.email) }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier_2], dossier_2.procedure.administrateurs.first.email) }
    end

    context 'when an instructeur is also administrateur' do
      let!(:administrateur) { procedure.administrateurs.first }
      let!(:dossier) { create(:dossier, :accepte, procedure: procedure, processed_at: (conservation_par_defaut - 1.month + 1.day).ago) }

      before do
        administrateur.instructeur.followed_dossiers << dossier
        ExpiredDossiersDeletionService.send_termine_expiration_notices
      end

      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).once }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).with([dossier], dossier.user.email) }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier], administrateur.email) }
    end
  end

  describe '#delete_expired_termine_and_notify' do
    before { Timecop.freeze(reference_date) }
    after  { Timecop.return }

    before do
      allow(DossierMailer).to receive(:notify_automatic_deletion_to_user).and_call_original
      allow(DossierMailer).to receive(:notify_automatic_deletion_to_administration).and_call_original
    end

    context 'with a single dossier' do
      let!(:dossier) { create(:dossier, :accepte, :followed, procedure: procedure, termine_close_to_expiration_notice_sent_at: notice_sent_at) }
      let(:deleted_dossier) { DeletedDossier.find_by(dossier_id: dossier.id) }

      before { ExpiredDossiersDeletionService.delete_expired_termine_and_notify }

      context 'when no notice has been sent' do
        let(:notice_sent_at) { nil }

        it { expect { dossier.reload }.not_to raise_error }
        it { expect(DossierMailer).not_to have_received(:notify_automatic_deletion_to_user) }
        it { expect(DossierMailer).not_to have_received(:notify_automatic_deletion_to_administration) }
      end

      context 'when a notice has been sent not so long ago' do
        let(:notice_sent_at) { (warning_period - 4.days).ago }

        it { expect { dossier.reload }.not_to raise_error }
        it { expect(DossierMailer).not_to have_received(:notify_automatic_deletion_to_user) }
        it { expect(DossierMailer).not_to have_received(:notify_automatic_deletion_to_administration) }
      end

      context 'when a notice has been sent a long time ago' do
        let(:notice_sent_at) { (warning_period + 4.days).ago }

        it { expect { dossier.reload }.to raise_error(ActiveRecord::RecordNotFound) }

        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).once }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).with([deleted_dossier], dossier.user.email) }

        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).twice }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([deleted_dossier], dossier.procedure.administrateurs.first.email) }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([deleted_dossier], dossier.followers_instructeurs.first.email) }
      end
    end

    context 'with 2 dossiers to delete' do
      let!(:dossier_1) { create(:dossier, :accepte, procedure: procedure, user: user, termine_close_to_expiration_notice_sent_at: (warning_period + 1.day).ago) }
      let!(:dossier_2) { create(:dossier, :refuse, procedure: procedure_2, user: user, termine_close_to_expiration_notice_sent_at: (warning_period + 1.day).ago) }
      let(:deleted_dossier_1) { DeletedDossier.find_by(dossier_id: dossier_1.id) }
      let(:deleted_dossier_2) { DeletedDossier.find_by(dossier_id: dossier_2.id) }

      let!(:instructeur) { create(:instructeur) }

      before do
        instructeur.followed_dossiers << dossier_1 << dossier_2
        ExpiredDossiersDeletionService.delete_expired_termine_and_notify
      end

      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).once }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).with(match_array([deleted_dossier_1, deleted_dossier_2]), user.email) }

      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).thrice }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with(match_array([deleted_dossier_1, deleted_dossier_2]), instructeur.email) }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([deleted_dossier_1], dossier_1.procedure.administrateurs.first.email) }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([deleted_dossier_2], dossier_2.procedure.administrateurs.first.email) }
    end
  end
end
