# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250424backfillDossierNotificationForAttenteAvisTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      let!(:follow_instructeur) { create(:instructeur) }
      let!(:not_follow_instructeur) { create(:instructeur) }
      let!(:groupe_instructeur) { create(:groupe_instructeur, instructeurs: [follow_instructeur, not_follow_instructeur]) }
      let!(:dossier) { create(:dossier, groupe_instructeur:) }

      context 'when a dossier has avis without answer and one follower instructeur' do
        let!(:avis) { create(:avis, dossier:) }
        let!(:follow) { create(:follow, dossier:, instructeur: follow_instructeur) }

        it do
          expect(collection).to eq([[dossier.id, [follow_instructeur.id]]])
        end
      end

      context 'when dossier has pending avis without answer but not follower instructeur' do
        let!(:avis) { create(:avis, dossier:) }

        it do
          expect(collection).to eq([[dossier.id, []]])
        end
      end

      context 'when dossier has not avis' do
        it do
          expect(collection).to eq([])
        end
      end

      context 'when dossier has avis without answer and attente_avis notification' do
        let!(:avis) { create(:avis, dossier:) }
        let!(:attente_avis_notification) { create(:dossier_notification, :for_instructeur, dossier:, instructeur: follow_instructeur, notification_type: :attente_avis) }

        it do
          expect(collection).to eq([])
        end
      end

      context 'when dossier has avis without answer but not attente_avis notification' do
        let!(:avis) { create(:avis, dossier:) }
        let!(:notification) { create(:dossier_notification, :for_instructeur, dossier:, instructeur: follow_instructeur) }

        it do
          expect(collection).to eq([[dossier.id, []]])
        end
      end
    end

    describe "#process" do
      let!(:dossier) { create(:dossier) }
      let!(:instructeur) { create(:instructeur) }

      context "when instructeur_ids is empty" do
        it "does not create any notification" do
          expect {
            described_class.process([dossier.id, []])
          }.not_to change(DossierNotification, :count)
        end
      end

      context "when a notification already exists for an instructeur" do
        let!(:notification) { create(:dossier_notification, :for_instructeur, dossier:, instructeur:, notification_type: :attente_avis) }

        it "does not create duplicate notification" do
          expect {
            described_class.process([dossier.id, [instructeur.id]])
          }.not_to change(DossierNotification, :count)
        end
      end

      context "when there are no existing notification" do
        it "creates notification" do
          expect {
            described_class.process([dossier.id, [instructeur.id]])
          }.to change(DossierNotification, :count).by(1)
        end
      end
    end
  end
end
