# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20251209destroyDossierNotificationForDossierSuppressionTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      let!(:notification_suppression) { create(:dossier_notification, instructeur: create(:instructeur), dossier:, notification_type: :dossier_suppression) }

      context 'when dossier is only hidden by administration' do
        let!(:dossier) { create(:dossier, :accepte, hidden_by_administration_at: Time.zone.yesterday) }

        it do
          expect(collection).to include(notification_suppression)
        end
      end

      context 'when dossier is hidden by administration and user' do
        let!(:dossier) { create(:dossier, :accepte, hidden_by_administration_at: Time.zone.yesterday, hidden_by_user_at: Time.zone.yesterday) }

        it do
          expect(collection).to include(notification_suppression)
        end
      end

      context 'when dossier is hidden by administration and expired' do
        let!(:dossier) { create(:dossier, :accepte, hidden_by_administration_at: Time.zone.yesterday, hidden_by_expired_at: Time.zone.yesterday) }

        it do
          expect(collection).to include(notification_suppression)
        end
      end

      context 'when dossier is only hidden by user' do
        let!(:dossier) { create(:dossier, :accepte, hidden_by_user_at: Time.zone.yesterday) }

        it do
          expect(collection).not_to include(notification_suppression)
        end
      end

      context 'when dossier is only hidden by automatic expired' do
        let!(:dossier) { create(:dossier, :en_construction, hidden_by_expired_at: Time.zone.yesterday) }

        it do
          expect(collection).not_to include(notification_suppression)
        end
      end
    end
  end
end
