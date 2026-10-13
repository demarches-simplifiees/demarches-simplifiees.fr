# frozen_string_literal: true

describe Columns::NotificationsColumn do
  describe '#sorted_ids' do
    let(:procedure) { create(:procedure, :published) }
    let(:column) { procedure.notifications_column }
    let(:dossiers) { procedure.dossiers }
    let(:instructeur) { create(:instructeur) }
    let!(:recent_dossier) { create(:dossier, :en_construction, procedure:) }
    let!(:older_dossier) { create(:dossier, :en_construction, procedure:) }

    subject { column.sorted_ids(dossiers, order, instructeur:) }

    before do
      recent_dossier.touch(time: Time.zone.local(2018, 9, 25))
      older_dossier.touch(time: Time.zone.local(2018, 5, 13))
    end

    context 'in ascending order' do
      let(:order) { 'asc' }

      it { is_expected.to eq([older_dossier, recent_dossier].map(&:id)) }
    end

    context 'in descending order' do
      let(:order) { 'desc' }

      let!(:dossier_notif) { create(:dossier, :en_construction, procedure:) }
      let!(:notif_instructeur_1) { create(:dossier_notification, instructeur:, dossier: dossier_notif, notification_type: :attente_avis) }
      let(:other_instructeur) { create(:instructeur) }
      let!(:notif_other_instructeur) { create(:dossier_notification, instructeur: other_instructeur, dossier: recent_dossier) }
      let!(:dossier_2_notif) { create(:dossier, :en_construction, procedure:) }
      let!(:notif_instructeur_2) { create(:dossier_notification, instructeur:, dossier: dossier_2_notif) }
      let!(:notif_not_display) { create(:dossier_notification, instructeur:, dossier: older_dossier, display_at: 1.day.from_now) }

      it { is_expected.to eq([dossier_2_notif, dossier_notif, recent_dossier, older_dossier].map(&:id)) }
    end
  end
end
