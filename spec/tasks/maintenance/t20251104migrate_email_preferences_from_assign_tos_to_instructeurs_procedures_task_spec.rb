# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20251104migrateEmailPreferencesFromAssignTosToInstructeursProceduresTask do
    let(:procedure) { create(:procedure) }
    let(:other_groupe_instructeur) { create(:groupe_instructeur, procedure:) }
    let(:instructeur) { create(:instructeur) }

    describe "#collection" do
      subject(:collection) { described_class.collection }

      context "when there is assign_to with default preferences" do
        let!(:ignored_assign_to) { create(:assign_to, procedure:, instructeur:) }
        let!(:keept_assign_to) { create(:assign_to, groupe_instructeur: other_groupe_instructeur, instructeur:, daily_email_notifications_enabled: true) }

        it "returns assign_to that have at least one preference with true" do
          expect(collection).to contain_exactly(keept_assign_to)
        end
      end

      context "when there are multiple assign_to for a same instructeur and procedure" do
        let!(:first_assign_to) { create(:assign_to, procedure:, instructeur:, daily_email_notifications_enabled: true) }
        let!(:second_assign_to) { create(:assign_to, groupe_instructeur: other_groupe_instructeur, instructeur:, daily_email_notifications_enabled: true) }

        it "returns a single assign_to by instructeur and procedure" do
          expect(collection.count).to eq(1)
        end
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(assign_to) }

      let!(:assign_to) { create(:assign_to, procedure:, instructeur:, daily_email_notifications_enabled: true) }

      context "when there is no existing InstructeursProcedure" do
        it "creates an InstructeursProcedure with last_revision_seen_id and position initialised, and updates email preferences" do
          expect { process }.to change(InstructeursProcedure, :count).by(1)

          ip = InstructeursProcedure.last
          expect(ip.instructeur_id).to eq(instructeur.id)
          expect(ip.procedure_id).to eq(procedure.id)
          expect(ip.last_revision_seen_id).to eq(procedure.published_revision_id)
          expect(ip.position).to eq(1)
          expect(ip.daily_email_summary).to be(true)
          expect(ip.instant_email_new_dossier).to be(false)
          expect(ip.instant_email_new_message).to be(false)
          expect(ip.instant_email_new_expert_avis).to be(false)
          expect(ip.weekly_email_summary).to be(false)
        end
      end

      context "when there is existing an InstructeursProcedure" do
        let!(:ip) { create(:instructeurs_procedure, instructeur:, procedure:, last_revision_seen_id: 123, position: 456) }

        it "only updates email preferences columns" do
          expect { process }.not_to change(InstructeursProcedure, :count)

          ip.reload

          expect(ip.last_revision_seen_id).to eq(123)
          expect(ip.position).to eq(456)
          expect(ip.daily_email_summary).to be(true)
          expect(ip.instant_email_new_message).to be(false)
          expect(ip.instant_email_new_dossier).to be(false)
          expect(ip.instant_email_new_expert_avis).to be(false)
          expect(ip.weekly_email_summary).to be(false)
        end
      end

      context "when the weekly_email_notifications_enabled is true " do
        before { assign_to.update(weekly_email_notifications_enabled: true) }

        it 'ignores this column and weekly_email_summary stay to false' do
          process
          ip = InstructeursProcedure.last

          expect(ip.weekly_email_summary).to be(false)
        end
      end
    end
  end
end
