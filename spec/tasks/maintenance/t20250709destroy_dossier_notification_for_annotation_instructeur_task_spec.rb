# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250709destroyDossierNotificationForAnnotationInstructeurTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      let(:dossier) { create(:dossier, last_champ_private_updated_at: last_champ_private_updated_at) }
      let(:instructeur) { create(:instructeur) }
      let!(:notification) { create(:dossier_notification, dossier:, instructeur:, notification_type: :annotation_instructeur) }

      context "when dossier has a private champ filled in" do
        let(:last_champ_private_updated_at) { 1.day.ago }

        it "not include the notification" do
          expect(collection).not_to include(notification)
        end
      end

      context "when dossier has no private champ filled in" do
        let(:last_champ_private_updated_at) { nil }

        it "include the notification" do
          expect(collection).to include(notification)
        end
      end
    end
  end
end
