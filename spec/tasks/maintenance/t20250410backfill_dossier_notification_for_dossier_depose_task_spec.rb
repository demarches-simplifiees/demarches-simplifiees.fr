# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250410backfillDossierNotificationForDossierDeposeTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      context 'dossier submitted more than 7 days ago but followed by an instructeur' do
        let(:dossier) { create(:dossier, :en_construction, :followed, depose_at: Time.current - 10.days) }

        it do
          expect(collection).not_to include(dossier)
        end
      end

      context 'dossier submitted less than 7 days ago' do
        let(:dossier) { create(:dossier, :en_construction, depose_at: Time.current) }

        it do
          expect(collection).not_to include(dossier)
        end
      end

      context 'dossier submitted more than 7 days ago, which already has an associated notification' do
        let!(:dossier) { create(:dossier, :en_construction, depose_at: Time.current - 10.days) }
        let!(:groupe_instructeur) {dossier.groupe_instructeur}
        let!(:notification) { create(:dossier_notification, :for_groupe_instructeur, dossier:, groupe_instructeur:) }

        it do
          expect(collection).not_to include(dossier)
        end
      end

      context 'dossier submitted more than 7 days ago, without an associated notification' do
        let(:dossier) { create(:dossier, :en_construction, depose_at: Time.current - 10.days) }

        it do
          expect(collection).to include(dossier)
        end
      end

      context 'dossier submitted more than 7 days ago, without an associated notification of type dossier_depose' do
        let!(:dossier) { create(:dossier, :en_construction, depose_at: Time.current - 10.days) }
        let!(:groupe_instructeur) {dossier.groupe_instructeur}
        let!(:notification) { create(:dossier_notification, :for_groupe_instructeur, dossier:, groupe_instructeur:, notification_type: 'attente_correction') }

        it do
          expect(collection).to include(dossier)
        end
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(dossier) }

      let!(:dossier) { create(:dossier, depose_at: Time.current - 10.days) }
      let!(:groupe_instructeur) { dossier.groupe_instructeur }

      context "when a notification already exists for an instructeur" do
        let!(:notification) { create(:dossier_notification, :for_groupe_instructeur, dossier:, groupe_instructeur:) }

        it "does not create duplicate notification" do
          expect{ process }.not_to change(DossierNotification, :count)
        end
      end

      context "when there are no existing notification" do
        it "creates notification" do
          expect{ process }.to change(DossierNotification, :count).by(1)
        end
      end
    end
  end
end
