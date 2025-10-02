# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250917destroyDossierNotificationForAttenteAvisTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      let(:dossier) { create(:dossier, dossier_state) }
      let(:instructeur) { create(:instructeur) }

      context "when dossier is not_termine with attente_avis notification" do
        let(:dossier_state) { :en_instruction }
        let!(:notification) { create(:dossier_notification, instructeur:, dossier:, notification_type: :attente_avis) }

        it "not include the notification" do
          expect(collection).not_to include(notification)
        end
      end

      context "when dossier is termine with other notification" do
        let(:dossier_state) { :accepte }
        let!(:other_notification) { create(:dossier_notification, instructeur:, dossier:, notification_type: :message) }

        it "not include the other notification" do
          expect(collection).not_to include(other_notification)
        end
      end

      context "when dossier is termine with attente_avis and other notification" do
        let(:dossier_state) { :accepte }
        let!(:notification) { create(:dossier_notification, instructeur:, dossier:, notification_type: :attente_avis) }
        let!(:other_notification) { create(:dossier_notification, instructeur:, dossier:, notification_type: :message) }

        it "include only dossier_depose notification" do
          expect(collection).to include(notification)
          expect(collection).not_to include(other_notification)
        end
      end
    end
  end
end
