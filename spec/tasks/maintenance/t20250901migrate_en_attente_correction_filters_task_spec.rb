# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250901migrateEnAttenteCorrectionFiltersTask do
    describe "#process" do
      let(:procedure) { create(:procedure) }
      let(:instructeur) { create(:instructeur) }
      let(:assign_to) { create(:assign_to, procedure: procedure, instructeur: instructeur) }
      let!(:procedure_presentation) { create(:procedure_presentation, assign_to: assign_to) }

      subject(:process) { described_class.process(procedure_presentation) }

      context "when procedure_presentation has filters" do
        context "one is 'pending_correction' on state" do
          before do
            procedure_presentation.update!(
              suivis_filters: [
                FilteredColumn.new(
                  column: procedure.dossier_state_column,
                  filter: "pending_correction"
                ),
                FilteredColumn.new(
                  column: procedure.dossier_id_column,
                  filter: "1"
                ),
              ]
            )
          end

          it "updates filter to notification == 'attente_correction'" do
            subject
            expect(procedure_presentation.suivis_filters.first.column).to eq(procedure.dossier_notifications_column)
            expect(procedure_presentation.suivis_filters.first.filter).to eq('attente_correction')
          end

          it "does not change other filter" do
            subject
            expect(procedure_presentation.suivis_filters.second.column).to eq(procedure.dossier_id_column)
            expect(procedure_presentation.suivis_filters.second.filter).to eq('1')
          end

          it "keeps the same number of filters" do
            subject
            expect(procedure_presentation.suivis_filters.count).to eq(2)
          end
        end

        context "one is not 'pending_correction' on state" do
          before do
            procedure_presentation.update!(
              suivis_filters: [
                FilteredColumn.new(
                  column: procedure.dossier_state_column,
                  filter: "en_construction"
                ),
              ]
            )
          end

          it "does not change filter" do
            subject
            expect(procedure_presentation.suivis_filters.count).to eq(1)
            expect(procedure_presentation.suivis_filters.first.column).to eq(procedure.dossier_state_column)
            expect(procedure_presentation.suivis_filters.first.filter).to eq('en_construction')
          end
        end
      end

      context "when procedure_presentation has no filter" do
        it "does not change procedure_presentation" do
          expect { subject }.not_to change { procedure_presentation }
        end
      end

      context "when procedure_presentation has notification_type filter" do
        context "which is already 'attente_correction'" do
          before do
            procedure_presentation.update!(
              suivis_filters: [
                FilteredColumn.new(
                  column: procedure.dossier_notifications_column,
                  filter: "attente_correction"
                ),
              ]
            )
          end

          it "does not change notification_type filter" do
            expect { process }.not_to change { procedure_presentation.suivis_filters.map(&:to_json) }
          end
        end
      end
    end
  end
end
