# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250625updateDossierNotificationMessageUsagerToMessageTask do
    let(:dossier) { create(:dossier) }
    let(:instructeur) { create(:instructeur) }
    let!(:notification_message_usager) do
      notification = DossierNotification.create!(dossier: dossier, instructeur: instructeur, notification_type: :message)
      notification.update_column(:notification_type, 'message_usager')
      notification
    end

    describe "#collection" do
      subject(:collection) { described_class.collection }

      let!(:other_notification) { create(:dossier_notification, :for_instructeur, dossier:, instructeur:, notification_type: :dossier_modifie) }

      it "includes only :message_usager notification" do
        expect(collection).to include(notification_message_usager)
        expect(collection).not_to include(other_notification)
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(notification_message_usager) }

      it "updates notification_type :message_usager to :message" do
        subject
        expect(notification_message_usager.notification_type).to eq('message')
      end
    end
  end
end
