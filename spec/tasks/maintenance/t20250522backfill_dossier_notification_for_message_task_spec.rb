# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250522backfillDossierNotificationForMessageTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      let(:instructeur) { create(:instructeur) }
      let!(:dossier_1) { create(:dossier, last_commentaire_updated_at: 2.days.ago) }
      let!(:follow_1) { create(:follow, dossier: dossier_1, instructeur:, messagerie_seen_at: 3.days.ago) }
      let!(:dossier_2) { create(:dossier, last_commentaire_updated_at: 2.days.ago) }
      let!(:follow_2) { create(:follow, dossier: dossier_2, instructeur:, messagerie_seen_at: 1.day.ago) }

      context "when the last message has been sent after the instructeur has consulted the message service" do
        it { expect(collection.map(&:id)).to include(follow_1.id) }
      end

      context "when the last message has been sent before the instructeur has consulted the message service" do
        it { expect(collection.map(&:id)).not_to include(follow_2.id) }
      end
    end

    describe "#process" do
      let!(:dossier) { create(:dossier) }
      let!(:instructeur) { create(:instructeur) }
      let!(:follow) { create(:follow, dossier:, instructeur:) }

      context "when a notification :messsage already exists" do
        let!(:notification) { create(:dossier_notification, :for_instructeur, dossier:, instructeur:, notification_type: :message) }

        it "does not create duplicate notification" do
          expect {
            described_class.process(follow)
          }.not_to change(DossierNotification, :count)
        end
      end

      context "when there are no existing notification" do
        it "creates notification" do
          expect {
            described_class.process(follow)
          }.to change(DossierNotification, :count).by(1)
        end
      end

      context "when a notification :message_usager already exists" do
        let!(:notification) do
          notification = DossierNotification.create!(dossier: dossier, instructeur: instructeur, notification_type: :message)
          notification.update_column(:notification_type, 'message_usager')
        end

        it "does not create duplicate notification" do
          expect {
            described_class.process(follow)
          }.not_to change(DossierNotification, :count)
        end
      end
    end
  end
end
