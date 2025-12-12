# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20251110backfillDossierNotificationForDossierSuppressionTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      context 'when dossier is not hidden' do
        let!(:dossier) { create(:dossier, :accepte, hidden_by_administration_at: nil, hidden_by_expired_at: nil, hidden_by_user_at: nil) }

        it do
          expect(collection).not_to include(dossier)
        end
      end

      context 'when dossier is only hidden by administration' do
        let!(:dossier) { create(:dossier, :accepte, hidden_by_administration_at: Time.zone.yesterday) }

        it do
          expect(collection).not_to include(dossier)
        end
      end

      context 'when dossier is only hidden by user' do
        let!(:dossier) { create(:dossier, :accepte, hidden_by_administration_at: Time.zone.yesterday) }

        it do
          expect(collection).not_to include(dossier)
        end
      end

      context 'when dossier is hidden by automatic expired' do
        let!(:dossier) { create(:dossier, :en_construction, hidden_by_expired_at: Time.zone.yesterday) }

        it do
          expect(collection).to include(dossier)
        end
      end

      context 'when dossier is hidden by user and administration' do
        let!(:dossier) { create(:dossier, :accepte, hidden_by_administration_at: Time.zone.yesterday, hidden_by_user_at: Time.zone.yesterday) }

        it do
          expect(collection).to include(dossier)
        end
      end

      context 'when dossier is hidden by administration and expired' do
        let!(:dossier) { create(:dossier, :accepte, hidden_by_administration_at: Time.zone.yesterday, hidden_by_expired_at: Time.zone.now) }

        it do
          expect(collection).to include(dossier)
        end
      end

      context 'when dossier is hidden by user and expired' do
        let!(:dossier) { create(:dossier, :accepte, hidden_by_user_at: Time.zone.yesterday, hidden_by_expired_at: Time.zone.now) }

        it do
          expect(collection).to include(dossier)
        end
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(dossier) }

      let(:groupe_instructeur) { create(:groupe_instructeur, instructeurs: [instructeur]) }
      let(:instructeur) { create(:instructeur) }

      context "when dossier is hidden by automatic expired" do
        let!(:dossier) { create(:dossier, :en_construction, groupe_instructeur:, hidden_by_expired_at: Time.zone.yesterday) }

        it "creates notification with correct delay" do
          expect { process }.to change(DossierNotification, :count).by(1)

          notification = DossierNotification.first
          expect(notification.dossier_id).to eq(dossier.id)
          expect(notification.instructeur_id).to eq(instructeur.id)
          expect(notification.notification_type).to eq('dossier_suppression')
          expect(notification.display_at.to_date).to eq(Time.zone.yesterday.to_date)
        end
      end

      context "when dossier is hidden by user and administration" do
        let!(:dossier) { create(:dossier, :accepte, groupe_instructeur:, hidden_by_administration_at: Time.zone.yesterday, hidden_by_user_at: Time.zone.now) }

        it "creates notification with correct delay" do
          expect { process }.to change(DossierNotification, :count).by(1)

          notification = DossierNotification.first
          expect(notification.dossier_id).to eq(dossier.id)
          expect(notification.instructeur_id).to eq(instructeur.id)
          expect(notification.notification_type).to eq('dossier_suppression')
          expect(notification.display_at.to_date).to eq(Time.zone.now.to_date)
        end
      end

      context 'when dossier is hidden by administration and expired' do
        let!(:dossier) { create(:dossier, :accepte, groupe_instructeur:, hidden_by_administration_at: Time.zone.yesterday, hidden_by_expired_at: Time.zone.now) }

        it "creates notification with correct delay" do
          expect { process }.to change(DossierNotification, :count).by(1)

          notification = DossierNotification.first
          expect(notification.dossier_id).to eq(dossier.id)
          expect(notification.instructeur_id).to eq(instructeur.id)
          expect(notification.notification_type).to eq('dossier_suppression')
          expect(notification.display_at.to_date).to eq(Time.zone.now.to_date)
        end
      end
    end
  end
end
