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
      let!(:groupe_instructeur_ids) { [groupe_instructeur.id, other_groupe_instructeur.id] }
      let!(:dossier_ids) { [dossier.id, other_dossier.id] }

      subject { DossierNotification.notifications_for_instructeur_dossiers(groupe_instructeur_ids, instructeur, dossier_ids) }

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
end
