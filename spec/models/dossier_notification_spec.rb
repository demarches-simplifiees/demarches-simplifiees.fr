# frozen_string_literal: true

RSpec.describe DossierNotification, type: :model do
  describe '.to_display' do
    let(:past_notification) { create(:dossier_notification, :for_groupe_instructeur) }
    let(:future_notification) { create(:dossier_notification, :for_groupe_instructeur, display_at: 1.day.from_now) }

    it 'includes notifications where display_at is in the past or now' do
      expect(DossierNotification.to_display).to include(past_notification)
    end

    it 'excludes notifications where display_at is in the future' do
      expect(DossierNotification.to_display).not_to include(future_notification)
    end
  end

  describe 'create_notification' do
    subject { DossierNotification.create_notification(dossier, notification_type, **notification_args) }

    let(:notification_args) { {} }

    context 'dossier_depose notification' do
      let(:procedure) { create(:procedure, sva_svr: {}, declarative_with_state: nil) }
      let(:groupe_instructeur) { create(:groupe_instructeur, procedure:) }
      let!(:dossier) { create(:dossier, groupe_instructeur:, depose_at: Time.zone.now, procedure:) }
      let!(:notification_type) { :dossier_depose }

      it 'create notification for the groupe_instructeur with the correct delay to display' do
        subject
        expect(DossierNotification.count).to eq(1)

        notification = DossierNotification.first
        expect(notification.dossier).to eq(dossier)
        expect(notification.groupe_instructeur).to eq(groupe_instructeur)
        expect(notification.instructeur).to be_nil
        expect(notification.notification_type).to eq('dossier_depose')
        expect(notification.display_at.to_date).to eq(dossier.depose_at.to_date + DossierNotification::DELAY_DOSSIER_DEPOSE)
      end

      it 'does not create notification when procedure is sva/svr' do
        procedure.update!(sva_svr: { 'decision' => 'sva' })
        dossier.procedure.reload
        subject

        expect(DossierNotification.count).to eq(0)
      end

      it 'does not create notification when procedure is declarative' do
        procedure.update!(declarative_with_state: "accepte")
        dossier.procedure.reload
        subject

        expect(DossierNotification.count).to eq(0)
      end
    end

    context "message notification" do
      let!(:dossier) { create(:dossier) }
      let(:instructeur_follower) { create(:instructeur) }
      let(:other_instructeur_follower) { create(:instructeur) }
      let(:instructeur_not_follower) { create(:instructeur) }
      let(:groupe_instructeur) { create(:groupe_instructeur, instructeurs: [instructeur_follower, other_instructeur_follower, instructeur_not_follower]) }
      let!(:notification_type) { :message }

      before do
        dossier.assign_to_groupe_instructeur(groupe_instructeur, DossierAssignment.modes.fetch(:auto))
        instructeur_follower.followed_dossiers << dossier
        other_instructeur_follower.followed_dossiers << dossier
      end

      context "when user or expert send a message" do
        it "create notification for instructeurs followers" do
          subject

          expect(DossierNotification.count).to eq(2)

          notifications = DossierNotification.where(dossier:, notification_type: :message)

          expect(notifications.map(&:instructeur_id)).to match_array([instructeur_follower.id, other_instructeur_follower.id])
        end
      end

      context "when instructeur send a message" do
        let!(:notification_args) { { except_instructeur: instructeur_follower } }

        it "create notification for instructeurs followers, except instructeur sender" do
          subject

          expect(DossierNotification.count).to eq(1)

          notification = DossierNotification.first
          expect(notification.dossier).to eq(dossier)
          expect(notification.groupe_instructeur).to be_nil
          expect(notification.instructeur).to eq(other_instructeur_follower)
          expect(notification.notification_type).to eq('message')
          expect(DossierNotification.to_display).to include(notification)
        end
      end
    end
  end

  describe '.notifications_for' do
    let!(:instructeur) { create(:instructeur) }
    let!(:groupe_instructeur) { create(:groupe_instructeur, instructeurs: [instructeur]) }
    let!(:other_groupe_instructeur) { create(:groupe_instructeur, instructeurs: [instructeur]) }
    let!(:dossier) { create(:dossier, :accepte, groupe_instructeur:) }
    let!(:other_dossier) { create(:dossier, :en_construction, groupe_instructeur: other_groupe_instructeur) }
    let!(:notification_instructeur) { create(:dossier_notification, :for_instructeur, dossier:, instructeur:) }
    let!(:notification_grp_instructeur) { create(:dossier_notification, :for_groupe_instructeur, dossier:, groupe_instructeur:) }
    let!(:other_notification_instructeur) { create(:dossier_notification, :for_instructeur, dossier: other_dossier, instructeur:) }
    let!(:other_notification_grp_instructeur) { create(:dossier_notification, :for_groupe_instructeur, dossier: other_dossier, groupe_instructeur: other_groupe_instructeur) }

    context 'a given instructeur and one dossier' do
      subject { DossierNotification.notifications_for_instructeur_dossier(instructeur, dossier) }

      it 'includes correct notifications and excludes the others' do
        is_expected.to include(notification_instructeur)
        is_expected.to include(notification_grp_instructeur)
        is_expected.not_to include(other_notification_instructeur)
        is_expected.not_to include(other_notification_grp_instructeur)
      end
    end

    context 'a given instructeur and a list of dossiers' do
      let!(:dossier_ids) { [dossier.id, other_dossier.id] }

      subject { DossierNotification.notifications_for_instructeur_dossiers(instructeur, dossier_ids) }

      it 'includes correct notifications and excludes the others' do
        expect(subject[dossier.id]).to include(notification_instructeur)
        expect(subject[dossier.id]).to include(notification_grp_instructeur)
        expect(subject[other_dossier.id]).to include(other_notification_instructeur)
        expect(subject[other_dossier.id]).to include(other_notification_grp_instructeur)
      end
    end

    context 'a given instructeur on a procedure' do
      let!(:groupe_instructeur_ids) { [groupe_instructeur.id, other_groupe_instructeur.id] }

      subject { DossierNotification.notifications_for_instructeur_procedure(groupe_instructeur_ids, instructeur) }

      it 'includes correct notifications and excludes the others' do
        expect(subject['traites']['dossier_depose']).to include(notification_instructeur)
        expect(subject['traites']['dossier_depose']).to include(notification_grp_instructeur)
        expect(subject['a-suivre']['dossier_depose']).to include(other_notification_instructeur)
        expect(subject['a-suivre']['dossier_depose']).to include(other_notification_grp_instructeur)
      end
    end
  end

  describe '.notifications_sticker_for' do
    let(:procedure) { create(:procedure) }
    let(:instructeur) { create(:instructeur) }
    let(:groupe_instructeur) { create(:groupe_instructeur, instructeurs: [instructeur]) }
    let(:other_groupe_instructeur) { create(:groupe_instructeur, instructeurs: [instructeur]) }
    let(:dossier) { create(:dossier, :accepte, procedure:, groupe_instructeur:) }
    let(:other_dossier) { create(:dossier, :en_construction, procedure:, groupe_instructeur: other_groupe_instructeur) }
    let!(:notification_news_instructeur) { create(:dossier_notification, :for_instructeur, dossier:, instructeur:, notification_type: :dossier_modifie) }
    let!(:notification_not_news_instructeur) { create(:dossier_notification, :for_instructeur, dossier:, instructeur:) }
    let!(:other_notification_news_instructeur) { create(:dossier_notification, :for_instructeur, dossier: other_dossier, instructeur:, notification_type: :annotation_instructeur) }
    let!(:other_notification_not_news_instructeur) { create(:dossier_notification, :for_instructeur, dossier: other_dossier, instructeur:) }

    context 'a given instructeur on one dossier' do
      subject { DossierNotification.notifications_sticker_for_instructeur_dossier(instructeur, dossier) }

      it do
        is_expected.to eq({
          demande: true,
          annotations_privees: false,
          avis_externe: false,
          messagerie: false
        })
      end
    end

    context 'a given instructeur on one procedure' do
      let!(:groupe_instructeur_ids) { [groupe_instructeur.id, other_groupe_instructeur.id] }
      let!(:dossier_ids) { [dossier.id, other_dossier.id] }

      subject { DossierNotification.notifications_sticker_for_instructeur_procedure(groupe_instructeur_ids, instructeur) }

      before do
        instructeur.followed_dossiers << other_dossier
      end

      it do
        is_expected.to eq({
          suivis: true,
          traites: true
        })
      end
    end

    context 'a given instructeur on a list of procedures' do
      let!(:groupe_instructeur_ids) { [groupe_instructeur.id, other_groupe_instructeur.id] }

      subject { DossierNotification.notifications_sticker_for_instructeur_procedures(groupe_instructeur_ids, instructeur) }

      before do
        instructeur.followed_dossiers << other_dossier
      end

      it do
        is_expected.to eq({
          suivis: [procedure.id],
          traites: [procedure.id]
        })
      end
    end
  end
end
