# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250410backfillDossierNotificationForDossierDeposeTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      context 'dossier submitted more than 7 days ago but followed by an instructeur' do
        let(:dossier) { create(:dossier, :en_construction, :followed, depose_at: 10.days.ago) }

        it do
          expect(collection).not_to include(dossier)
        end
      end

      context 'dossier submitted less than 7 days ago' do
        let(:dossier) { create(:dossier, :en_construction, depose_at: 1.day.ago) }

        it do
          expect(collection).not_to include(dossier)
        end
      end

      context 'dossier submitted more than 7 days ago' do
        let(:dossier) { create(:dossier, :en_construction, depose_at: 10.days.ago) }

        it do
          expect(collection).to include(dossier)
        end
      end

      context 'dossier not in state en_construction' do
        # case of automatic switch en_instruction when the dossier is submitted
        # (SVA/SVR, declarative procedure), and case of dossiers that have been
        # unfollowed after the switch en_instruction.
        let(:dossier) { create(:dossier, :en_instruction, depose_at: 10.days.ago) }

        it do
          expect(collection).not_to include(dossier)
        end
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(dossier) }

      let!(:dossier) { create(:dossier, depose_at: 10.days.ago) }
      let!(:groupe_instructeur) { dossier.groupe_instructeur }

      context "when a notification already exists for an instructeur" do
        let!(:notification) { create(:dossier_notification, :for_groupe_instructeur, dossier:, groupe_instructeur:) }

        it "does not create duplicate notification" do
          expect { process }.not_to change(DossierNotification, :count)
        end
      end

      context "when there are no existing notification" do
        it "creates notification" do
          expect { process }.to change(DossierNotification, :count).by(1)
        end
      end
    end
  end
end
