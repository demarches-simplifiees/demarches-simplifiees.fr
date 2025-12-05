# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20251106backfillDossierNotificationForDossierExpirantTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      let!(:dossier) { create(:dossier, :en_construction) }

      context 'when dossier is not close to expiration' do
        before { dossier.update(expired_at: 1.month.from_now) }

        it do
          expect(collection).not_to include(dossier)
        end
      end

      context 'when dossier is close to expiration' do
        before { dossier.update(expired_at: 1.week.from_now) }

        it do
          expect(collection).to include(dossier)
        end
      end

      context 'when dossier is close to expiration and hidden by administration' do
        let!(:dossier) { create(:dossier, :accepte) }

        before { dossier.update(expired_at: 1.week.from_now, hidden_by_administration_at: Time.zone.yesterday) }

        it do
          expect(collection).to include(dossier)
        end
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(dossier) }

      let!(:dossier) { create(:dossier, :en_construction, groupe_instructeur:) }
      let(:groupe_instructeur) { create(:groupe_instructeur, instructeurs: [instructeur]) }
      let(:instructeur) { create(:instructeur) }

      before { dossier.update(expired_at: 1.week.from_now) }

      it "creates notification with correct delay" do
        expect { process }.to change(DossierNotification, :count).by(1)

        notification = DossierNotification.first
        expect(notification.dossier_id).to eq(dossier.id)
        expect(notification.instructeur_id).to eq(instructeur.id)
        expect(notification.notification_type).to eq('dossier_expirant')
        expect(notification.display_at.to_date).to eq(1.week.ago.to_date)
      end
    end
  end
end
