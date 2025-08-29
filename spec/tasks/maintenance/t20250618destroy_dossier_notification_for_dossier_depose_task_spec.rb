# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250618destroyDossierNotificationForDossierDeposeTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      let(:dossier) { create(:dossier, dossier_state) }
      let(:instructeur) { create(:instructeur) }

      context "when dossier is en_construction with dossier_depose notification" do
        let(:dossier_state) { :en_construction }
        let!(:notification_dossier_depose) { create(:dossier_notification, instructeur:, dossier:) }

        it "not include the notification" do
          expect(collection).not_to include(notification_dossier_depose)
        end
      end

      context "when dossier is not en_construction with other notification" do
        let(:dossier_state) { :en_instruction }
        let!(:other_notification) { create(:dossier_notification, instructeur:, dossier:, notification_type: :dossier_modifie) }

        it "not include the other notification" do
          expect(collection).not_to include(other_notification)
        end
      end

      context "when dossier is not en_construction with dossier_depose and other notification" do
        let(:dossier_state) { :accepte }
        let!(:notification_dossier_depose) { create(:dossier_notification, instructeur:, dossier:) }
        let!(:other_notification) { create(:dossier_notification, instructeur:, dossier:, notification_type: :dossier_modifie) }

        it "include only dossier_depose notification" do
          expect(collection).to include(notification_dossier_depose)
          expect(collection).not_to include(other_notification)
        end
      end
    end
  end
end
