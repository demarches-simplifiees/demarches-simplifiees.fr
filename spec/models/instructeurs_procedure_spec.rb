# frozen_string_literal: true

RSpec.describe InstructeursProcedure, type: :model do
  describe '.update_instructeur_procedures_positions' do
    let(:instructeur) { create(:instructeur) }
    let!(:procedures) { create_list(:procedure, 5, published_at: Time.current) }

    before do
      procedures.each_with_index do |procedure, index|
        create(:instructeurs_procedure, instructeur: instructeur, procedure: procedure, position: index + 1)
      end
    end

    it 'updates the positions of the specified instructeurs_procedures' do
      InstructeursProcedure.update_instructeur_procedures_positions(instructeur, procedures.map(&:id))

      updated_positions = InstructeursProcedure
        .where(instructeur:)
        .order(:procedure_id)
        .pluck(:procedure_id, :position)

      expect(updated_positions).to match_array([
        [procedures[0].id, 4],
        [procedures[1].id, 3],
        [procedures[2].id, 2],
        [procedures[3].id, 1],
        [procedures[4].id, 0]
      ])
    end
  end

  describe '.refresh_notifications' do
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure) }
    let!(:instructeur_procedure) { create(:instructeurs_procedure, instructeur:, procedure:) }
    let(:groupe_instructeur) { create(:groupe_instructeur, procedure:, instructeurs: [instructeur]) }
    let!(:dossier_followed_to_notify) { create(:dossier, :en_construction, groupe_instructeur:, procedure:, last_champ_updated_at: Time.zone.now, depose_at: Time.zone.yesterday) }
    let!(:dossier_not_followed_to_notify) { create(:dossier, :en_construction, groupe_instructeur:, procedure:, last_champ_updated_at: Time.zone.now, depose_at: Time.zone.yesterday) }
    let!(:follow) { create(:follow, instructeur:, dossier: dossier_followed_to_notify) }
    let(:old_preferences) {
      {
        dossier_depose: 'all',
        dossier_modifie: 'followed',
        message: 'followed',
        annotation_instructeur: 'followed',
        avis_externe: 'followed',
        attente_correction: 'followed',
        attente_avis: 'followed'
      }
    }
    let(:new_preferences) {
      {
        dossier_depose: 'all',
        dossier_modifie: 'followed',
        message: 'followed',
        annotation_instructeur: 'followed',
        avis_externe: 'followed',
        attente_correction: 'followed',
        attente_avis: 'followed'
      }
    }

    subject { instructeur_procedure.refresh_notifications([groupe_instructeur.id], old_preferences, new_preferences) }

    context "when instructeur has not changed their preference" do
      let!(:notification) { create(:dossier_notification, dossier: dossier_followed_to_notify, instructeur:, notification_type: :dossier_modifie) }

      it "does not change notifications" do
        expect { subject }.not_to change(DossierNotification, :count)
      end
    end

    context "when instructeur changes a preference from 'all' to 'none' " do
      let!(:notification_dossier_followed) { create(:dossier_notification, dossier: dossier_followed_to_notify, instructeur:, notification_type: :dossier_modifie) }
      let!(:notification_dossier_not_followed) { create(:dossier_notification, dossier: dossier_not_followed_to_notify, instructeur:, notification_type: :dossier_modifie) }

      before do
        old_preferences[:dossier_modifie] = 'all'
        new_preferences[:dossier_modifie] = 'none'
      end

      it "destroys notifications of notification_type in question on all dossiers" do
        expect { subject }.to change(DossierNotification, :count).to eq(0)
      end
    end

    context "when instructeur changes a preference from 'followed' to 'none' " do
      let!(:notification_dossier_followed) { create(:dossier_notification, dossier: dossier_followed_to_notify, instructeur:, notification_type: :dossier_modifie) }

      before do
        old_preferences[:dossier_modifie] = 'followed'
        new_preferences[:dossier_modifie] = 'none'
      end

      it "destroys notifications of notification_type in question on followed dossiers" do
        expect { subject }.to change(DossierNotification, :count).to eq(0)
      end
    end

    context "when instructeur changes a preference from 'all' to 'followed' " do
      let!(:notification_dossier_followed) { create(:dossier_notification, dossier: dossier_followed_to_notify, instructeur:, notification_type: :dossier_modifie) }
      let!(:notification_dossier_not_followed) { create(:dossier_notification, dossier: dossier_not_followed_to_notify, instructeur:, notification_type: :dossier_modifie) }

      before do
        old_preferences[:dossier_modifie] = 'all'
        new_preferences[:dossier_modifie] = 'followed'
      end

      it "destroys notifications of notification_type in question only on no followed dossiers" do
        subject

        expect(DossierNotification.count).to eq(1)
        expect(DossierNotification.all).to include(notification_dossier_followed)
      end
    end

    context "when instructeur changes a preference from 'none' to 'all' " do
      before do
        old_preferences[:dossier_modifie] = 'none'
        new_preferences[:dossier_modifie] = 'all'
      end

      it "creates notifications of notification_type in question on all dossiers" do
        subject

        expect(DossierNotification.count).to eq(2)
        expect(DossierNotification.all.map(&:instructeur_id).uniq).to eq([instructeur.id])
        expect(DossierNotification.all.map(&:notification_type).uniq).to eq(['dossier_modifie'])
        expect(DossierNotification.all.map(&:dossier_id)).to match_array([dossier_followed_to_notify.id, dossier_not_followed_to_notify.id])
      end
    end

    context "when instructeur changes a preference from 'followed' to 'all' " do
      before do
        old_preferences[:dossier_modifie] = 'followed'
        new_preferences[:dossier_modifie] = 'all'
      end

      it "creates notifications of notification_type in question only on not followed dossiers" do
        subject

        expect(DossierNotification.count).to eq(1)
        expect(DossierNotification.first.instructeur_id).to eq(instructeur.id)
        expect(DossierNotification.first.notification_type).to eq('dossier_modifie')
        expect(DossierNotification.first.dossier_id).to eq(dossier_not_followed_to_notify.id)
      end
    end

    context "when instructeur changes a preference from 'none' to 'followed' " do
      before do
        old_preferences[:dossier_modifie] = 'none'
        new_preferences[:dossier_modifie] = 'followed'
      end

      it "creates notifications of notification_type in question only on followed dossiers" do
        subject

        expect(DossierNotification.count).to eq(1)
        expect(DossierNotification.first.instructeur_id).to eq(instructeur.id)
        expect(DossierNotification.first.notification_type).to eq('dossier_modifie')
        expect(DossierNotification.first.dossier_id).to eq(dossier_followed_to_notify.id)
      end
    end
  end
end
