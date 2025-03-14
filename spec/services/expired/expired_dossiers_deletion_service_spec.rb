# frozen_string_literal: true

describe Expired::DossiersDeletionService do
  let(:warning_period) { 1.month + 5.days }
  let(:conservation_par_defaut) { 3.months }
  let(:user) { create(:user) }
  let(:procedure_opts) { {} }
  let(:procedure) { create(:procedure, :published, procedure_opts) }
  let(:procedure_2) { create(:procedure, :published, :new_administrateur, procedure_opts) }
  let(:reference_date) { Date.parse("March 8") }
  let(:service) { Expired::DossiersDeletionService.new }

  describe '#process_expired_dossiers_brouillon' do
    before { travel_to(reference_date) }

    let(:today) { Time.zone.now.at_beginning_of_day }
    let(:date_close_to_expiration) { today - procedure.duree_conservation_dossiers_dans_ds.months + 13.days }
    let(:date_expired) { today - procedure.duree_conservation_dossiers_dans_ds.months - 6.days }
    let(:date_not_expired) { today - procedure.duree_conservation_dossiers_dans_ds.months + 2.months }

    context 'send messages for dossiers expiring soon and delete expired' do
      let!(:expired_brouillon) { create(:dossier, procedure: procedure, updated_at: date_expired, brouillon_close_to_expiration_notice_sent_at: today - (warning_period + 3.days)) }
      let!(:brouillon_close_to_expiration) { create(:dossier, procedure: procedure, updated_at: date_close_to_expiration) }
      let!(:brouillon_close_but_with_notice_sent) { create(:dossier, procedure: procedure, updated_at: date_close_to_expiration, brouillon_close_to_expiration_notice_sent_at: Time.zone.now) }
      let!(:valid_brouillon) { create(:dossier, procedure: procedure, updated_at: date_not_expired) }

      before do
        allow(DossierMailer).to receive(:notify_brouillon_near_deletion).and_call_original
        allow(DossierMailer).to receive(:notify_brouillon_deletion).and_call_original

        service.process_expired_dossiers_brouillon
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
    before { travel_to(reference_date) }

    before do
      allow(DossierMailer).to receive(:notify_brouillon_near_deletion).and_return(double(deliver_later: nil))
    end

    context 'with a single dossier' do
      let!(:dossier) { create(:dossier, procedure: procedure, updated_at: updated_at) }

      before { service.send_brouillon_expiration_notices }

      context 'when the dossier is not close to expiration' do
        let(:updated_at) { (conservation_par_defaut - 2.weeks - 1.day).ago }

        it { expect(dossier.reload.brouillon_close_to_expiration_notice_sent_at).to be_nil }
        it { expect(DossierMailer).not_to have_received(:notify_brouillon_near_deletion) }
      end

      context 'when the dossier is close to expiration' do
        let(:updated_at) { (conservation_par_defaut - 2.weeks + 1.day).ago }

        it { expect(dossier.reload.brouillon_close_to_expiration_notice_sent_at).not_to be_nil }
        it { expect(DossierMailer).to have_received(:notify_brouillon_near_deletion).once }
        it { expect(DossierMailer).to have_received(:notify_brouillon_near_deletion).with([dossier], dossier.user.email) }
      end
    end

    context 'with 2 dossiers to notice' do
      let!(:dossier_1) { create(:dossier, procedure: procedure, user: user, updated_at: (conservation_par_defaut - 2.weeks + 1.day).ago) }
      let!(:dossier_2) { create(:dossier, procedure: procedure_2, user: user, updated_at: (conservation_par_defaut - 2.weeks + 1.day).ago) }

      before { service.send_brouillon_expiration_notices }

      it { expect(DossierMailer).to have_received(:notify_brouillon_near_deletion).once }
      it { expect(DossierMailer).to have_received(:notify_brouillon_near_deletion).with(match_array([dossier_1, dossier_2]), user.email) }
    end
  end

  describe '#delete_expired_brouillons_and_notify' do
    before { travel_to(reference_date) }

    before do
      allow(DossierMailer).to receive(:notify_brouillon_deletion).and_return(double(deliver_later: nil))
    end

    context 'with a single dossier' do
      let!(:dossier) { create(:dossier, procedure: procedure, brouillon_close_to_expiration_notice_sent_at: notice_sent_at) }

      before { service.delete_expired_brouillons_and_notify }

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
      let!(:dossier_1) { create(:dossier, procedure: procedure, user: user, brouillon_close_to_expiration_notice_sent_at: (warning_period + 1.day).ago) }
      let!(:dossier_2) { create(:dossier, procedure: procedure_2, user: user, brouillon_close_to_expiration_notice_sent_at: (warning_period + 1.day).ago) }

      before { service.delete_expired_brouillons_and_notify }

      it { expect(DossierMailer).to have_received(:notify_brouillon_deletion).once }
      it { expect(DossierMailer).to have_received(:notify_brouillon_deletion).with(match_array([dossier_1.hash_for_deletion_mail, dossier_2.hash_for_deletion_mail]), user.email) }
    end
  end

  describe '#send_en_construction_expiration_notices' do
    before { travel_to(reference_date) }

    before do
      allow(DossierMailer).to receive(:notify_near_deletion_to_user).and_return(double(deliver_later: nil))
      allow(DossierMailer).to receive(:notify_near_deletion_to_administration).and_return(double(deliver_later: nil))
    end

    context 'with a single dossier' do
      let!(:dossier) { create(:dossier, :en_construction, :followed, procedure: procedure, en_construction_at: en_construction_at) }

      before { service.send_en_construction_expiration_notices }

      context 'when the dossier is not near deletion' do
        let(:en_construction_at) { (conservation_par_defaut - 2.weeks - 1.day).ago }

        it { expect(dossier.reload.en_construction_close_to_expiration_notice_sent_at).to be_nil }
        it { expect(DossierMailer).not_to have_received(:notify_near_deletion_to_user) }
        it { expect(DossierMailer).not_to have_received(:notify_near_deletion_to_administration) }
      end

      context 'when the dossier is near deletion' do
        let(:en_construction_at) { (conservation_par_defaut - 2.weeks + 1.day).ago }

        it { expect(dossier.reload.en_construction_close_to_expiration_notice_sent_at).not_to be_nil }

        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).once }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).twice }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).with([dossier], dossier.user.email) }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier], dossier.procedure.administrateurs.first.email) }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier], dossier.followers_instructeurs.first.email) }
      end
    end

    context 'with 2 dossiers to notice' do
      let!(:dossier_1) { create(:dossier, :en_construction, procedure: procedure, user: user, en_construction_at: (conservation_par_defaut - 2.weeks + 1.day).ago) }
      let!(:dossier_2) { create(:dossier, :en_construction, procedure: procedure_2, user: user, en_construction_at: (conservation_par_defaut - 2.weeks + 1.day).ago) }

      let!(:instructeur) { create(:instructeur) }

      before do
        instructeur.followed_dossiers << dossier_1 << dossier_2
        service.send_en_construction_expiration_notices
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
      let!(:dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: (conservation_par_defaut - 2.weeks + 1.day).ago) }

      before do
        administrateur.instructeur.followed_dossiers << dossier
        service.send_en_construction_expiration_notices
      end

      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).once }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).with([dossier], dossier.user.email) }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier], administrateur.email) }
    end
  end

  describe '#delete_expired_en_construction_and_notify' do
    let!(:warning_period) { 1.month + 5.days }

    before { travel_to(reference_date) }

    before do
      allow(DossierMailer).to receive(:notify_automatic_deletion_to_user).and_call_original
      allow(DossierMailer).to receive(:notify_automatic_deletion_to_administration).and_call_original
    end

    context 'with a single dossier' do
      let!(:dossier) { create(:dossier, :en_construction, :followed, procedure: procedure, en_construction_close_to_expiration_notice_sent_at: notice_sent_at) }

      before { service.delete_expired_en_construction_and_notify }

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

        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).once }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).with([dossier], dossier.user.email) }

        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).twice }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([dossier], dossier.procedure.administrateurs.first.email) }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([dossier], dossier.followers_instructeurs.first.email) }

        it { expect(dossier.reload.hidden_by_user_at).to eq(nil) }
        it { expect(dossier.reload.hidden_by_administration_at).to eq(nil) }
        it { expect(dossier.reload.hidden_by_expired_at).to be_an_instance_of(ActiveSupport::TimeWithZone) }
        it { expect(dossier.reload.hidden_by_reason).to eq('expired') }
      end
    end

    context 'with 2 dossiers to delete' do
      let!(:dossier_1) { create(:dossier, :en_construction, procedure: procedure, user: user, en_construction_close_to_expiration_notice_sent_at: (warning_period + 1.day).ago) }
      let!(:dossier_2) { create(:dossier, :en_construction, procedure: procedure_2, user: user, en_construction_close_to_expiration_notice_sent_at: (warning_period + 1.day).ago) }

      let!(:instructeur) { create(:instructeur) }

      before do
        instructeur.followed_dossiers << dossier_1 << dossier_2
        service.delete_expired_en_construction_and_notify
      end

      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).once }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).with(match_array([dossier_1, dossier_2]), user.email) }

      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).thrice }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with(match_array([dossier_1, dossier_2]), instructeur.email) }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([dossier_1], dossier_1.procedure.administrateurs.first.email) }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([dossier_2], dossier_2.procedure.administrateurs.first.email) }

      it { expect(dossier_1.reload.hidden_by_expired_at).to be_an_instance_of(ActiveSupport::TimeWithZone) }
      it { expect(dossier_1.reload.hidden_by_reason).to eq('expired') }
      it { expect(dossier_2.reload.hidden_by_expired_at).to be_an_instance_of(ActiveSupport::TimeWithZone) }
      it { expect(dossier_2.reload.hidden_by_reason).to eq('expired') }
    end
  end

  describe '#send_termine_expiration_notices' do
    before { travel_to(reference_date) }
    let(:procedure_opts) do
      {
        procedure_expires_when_termine_enabled: true
      }
    end
    before do
      allow(DossierMailer).to receive(:notify_near_deletion_to_user).and_call_original
      allow(DossierMailer).to receive(:notify_near_deletion_to_administration).and_call_original
    end

    context 'with a single dossier' do
      let!(:dossier) { create(:dossier, :followed, state: :accepte, procedure: procedure, processed_at: processed_at) }

      before { service.send_termine_expiration_notices }

      context 'when the dossier is not near deletion' do
        let(:processed_at) { (conservation_par_defaut - 2.weeks - 1.day).ago }

        it { expect(dossier.reload.termine_close_to_expiration_notice_sent_at).to be_nil }
        it { expect(DossierMailer).not_to have_received(:notify_near_deletion_to_user) }
        it { expect(DossierMailer).not_to have_received(:notify_near_deletion_to_administration) }
      end

      context 'when the dossier is near deletion' do
        let(:processed_at) { (conservation_par_defaut - 2.weeks + 1.day).ago }

        it { expect(dossier.reload.termine_close_to_expiration_notice_sent_at).not_to be_nil }

        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).once }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).twice }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).with([dossier], dossier.user.email) }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier], dossier.procedure.administrateurs.first.email) }
        it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier], dossier.followers_instructeurs.first.email) }
      end
    end

    context 'with 2 dossiers to notice' do
      let!(:dossier_1) { create(:dossier, state: :accepte, procedure: procedure, user: user, processed_at: (conservation_par_defaut - 2.weeks + 1.day).ago) }
      let!(:dossier_2) { create(:dossier, state: :accepte, procedure: procedure_2, user: user, processed_at: (conservation_par_defaut - 2.weeks + 1.day).ago) }

      let!(:instructeur) { create(:instructeur) }

      before do
        instructeur.followed_dossiers << dossier_1 << dossier_2
        service.send_termine_expiration_notices
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
      let!(:dossier) { create(:dossier, state: :accepte, procedure: procedure, processed_at: (conservation_par_defaut - 2.weeks + 1.day).ago) }

      before do
        administrateur.instructeur.followed_dossiers << dossier
        service.send_termine_expiration_notices
      end

      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).once }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_user).with([dossier], dossier.user.email) }
      it { expect(DossierMailer).to have_received(:notify_near_deletion_to_administration).with([dossier], administrateur.email) }
    end
  end

  describe '#delete_expired_termine_and_notify' do
    before { travel_to(reference_date) }

    let(:procedure_opts) do
      {
        procedure_expires_when_termine_enabled: true
      }
    end

    before do
      allow(DossierMailer).to receive(:notify_automatic_deletion_to_user).and_call_original
      allow(DossierMailer).to receive(:notify_automatic_deletion_to_administration).and_call_original
    end

    context 'with a single dossier' do
      let!(:dossier) { create(:dossier, :followed, :accepte, procedure: procedure, termine_close_to_expiration_notice_sent_at: notice_sent_at) }

      before { service.delete_expired_termine_and_notify }

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

        it { expect(dossier.reload.hidden_by_expired_at).to be_an_instance_of(ActiveSupport::TimeWithZone) }
        it { expect(dossier.reload.hidden_by_reason).to eq('expired') }

        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).once }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).with([dossier], dossier.user.email) }

        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).twice }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([dossier], dossier.procedure.administrateurs.first.email) }
        it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([dossier], dossier.followers_instructeurs.first.email) }
      end
    end

    context 'with 2 dossiers to delete' do
      let!(:dossier_1) { create(:dossier, :accepte, procedure: procedure, user: user, termine_close_to_expiration_notice_sent_at: (warning_period + 1.day).ago) }
      let!(:dossier_2) { create(:dossier, :refuse, procedure: procedure_2, user: user, termine_close_to_expiration_notice_sent_at: (warning_period + 1.day).ago) }

      let!(:instructeur) { create(:instructeur) }

      before do
        instructeur.followed_dossiers << dossier_1 << dossier_2
        service.delete_expired_termine_and_notify
      end

      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).once }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).with(match_array([dossier_1, dossier_2]), user.email) }

      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).thrice }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with(match_array([dossier_1, dossier_2]), instructeur.email) }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([dossier_1], dossier_1.procedure.administrateurs.first.email) }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([dossier_2], dossier_2.procedure.administrateurs.first.email) }

      it { expect(dossier_1.reload.hidden_by_expired_at).to be_an_instance_of(ActiveSupport::TimeWithZone) }
      it { expect(dossier_1.reload.hidden_by_reason).to eq('expired') }
      it { expect(dossier_2.reload.hidden_by_expired_at).to be_an_instance_of(ActiveSupport::TimeWithZone) }
      it { expect(dossier_2.reload.hidden_by_reason).to eq('expired') }
    end

    context 'with 1 dossier deleted by user and 1 dossier deleted by administration' do
      let!(:dossier_1) { create(:dossier, :accepte, procedure: procedure, user: user, hidden_by_administration_at: 1.hour.ago, termine_close_to_expiration_notice_sent_at: (warning_period + 1.day).ago) }
      let!(:dossier_2) { create(:dossier, :refuse, procedure: procedure_2, user: user, hidden_by_user_at: 1.hour.ago, termine_close_to_expiration_notice_sent_at: (warning_period + 1.day).ago) }

      let!(:instructeur) { create(:instructeur) }

      before do
        instructeur.followed_dossiers << dossier_1 << dossier_2
        service.delete_expired_termine_and_notify
      end

      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).once }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_user).with(match_array([dossier_1]), user.email) }

      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).twice }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with(match_array([dossier_2]), instructeur.email) }
      it { expect(DossierMailer).to have_received(:notify_automatic_deletion_to_administration).with([dossier_2], dossier_2.procedure.administrateurs.first.email) }
    end
  end

  describe 'all_user_dossiers_brouillon_close_to_expiration' do
    before { travel_to(reference_date) }

    let(:today) { Time.zone.now.at_beginning_of_day }
    let(:date_expired) { today - procedure.duree_conservation_dossiers_dans_ds.months - 6.days }
    let(:user) { create(:user) }
    let!(:expired_brouillon_1) { create(:dossier, procedure:, user:, updated_at: date_expired) }
    let!(:expired_brouillon_2) { create(:dossier, procedure:, user:, updated_at: date_expired) }

    it 'find additional dossiers' do
      expired_brouillon_1
      expired_brouillon_2
      expect(Expired::DossiersDeletionService.new.send(:all_user_dossiers_brouillon_close_to_expiration, user))
        .to contain_exactly(expired_brouillon_1, expired_brouillon_2)
    end
  end
end
