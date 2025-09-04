# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250522backfillDossierNotificationForAvisExterneTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      let(:instructeur) { create(:instructeur) }
      let!(:dossier_1) { create(:dossier, last_avis_updated_at: 2.days.ago) }
      let!(:follow_1) { create(:follow, dossier: dossier_1, instructeur:, avis_seen_at: 3.days.ago) }
      let!(:dossier_2) { create(:dossier, last_avis_updated_at: 2.days.ago) }
      let!(:follow_2) { create(:follow, dossier: dossier_2, instructeur:, avis_seen_at: 1.day.ago) }

      context "when the dossier has been updated before the instructeur last saw it" do
        it { expect(collection.map(&:id)).to include(follow_1.id) }
      end

      context "when the dossier has been updated after the instructeur last saw it" do
        it { expect(collection.map(&:id)).not_to include(follow_2.id) }
      end
    end

    describe "#process" do
      let!(:dossier) { create(:dossier) }
      let!(:instructeur) { create(:instructeur) }
      let!(:follow) { create(:follow, dossier:, instructeur:) }

      context "when a notification already exists for an instructeur" do
        let!(:notification) { create(:dossier_notification, dossier:, instructeur:, notification_type: :avis_externe) }

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
    end
  end
end
