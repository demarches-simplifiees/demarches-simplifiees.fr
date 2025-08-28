# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250804backfillDossierDeposeNotificationForInstructeurTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      context 'dossier followed by an instructeur and en_construction' do
        let(:dossier) { create(:dossier, :en_construction, :followed) }

        it do
          expect(collection).not_to include(dossier)
        end
      end

      context 'dossier not en_construction and followed' do
        let(:dossier) { create(:dossier, :en_instruction, :followed) }

        it do
          expect(collection).not_to include(dossier)
        end
      end

      context 'dossier en_construction and not followed' do
        let(:dossier) { create(:dossier, :en_construction) }

        it do
          expect(collection).to include(dossier)
        end
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(dossier) }

      let!(:dossier) { create(:dossier, depose_at: 10.days.ago, groupe_instructeur:) }
      let(:groupe_instructeur) { create(:groupe_instructeur, instructeurs: [instructeur]) }
      let(:instructeur) { create(:instructeur) }

      it "creates notification" do
        expect { process }.to change(DossierNotification, :count).by(1)

        notification = DossierNotification.first
        expect(notification.dossier_id).to eq(dossier.id)
        expect(notification.instructeur_id).to eq(instructeur.id)
        expect(notification.notification_type).to eq('dossier_depose')
        expect(notification.display_at.to_date).to eq((10.days.ago + DossierNotification::DELAY_DOSSIER_DEPOSE).to_date)
      end
    end
  end
end
