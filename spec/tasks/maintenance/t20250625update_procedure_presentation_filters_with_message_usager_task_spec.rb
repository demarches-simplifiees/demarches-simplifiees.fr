# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250625updateProcedurePresentationFiltersWithMessageUsagerTask do
    let(:procedure) { create(:procedure) }
    let(:instructeur) { create(:instructeur) }
    let(:assign_to) { create(:assign_to, procedure: procedure, instructeur: instructeur) }
    let!(:procedure_presentation) { create(:procedure_presentation, assign_to: assign_to) }

    describe "#process" do
      subject(:process) { described_class.process(procedure_presentation) }

      context "when procedure_presentation has not filter" do
        it "does not change procedure_presentation" do
          expect { process }.not_to change { procedure_presentation }
        end
      end

      context "when procedure_presentation has filters but none on notification_type" do
        before do
          procedure_presentation.update!(
            suivis_filters: [
              FilteredColumn.new(
                column: procedure.dossier_id_column,
                filter: "1"
              ),
            ]
          )
        end

        it "does not change procedure_presentation filters" do
          expect { process }.not_to change { procedure_presentation }
        end
      end

      context "when procedure_presentation has notification_type filter" do
        context "which is not 'message_usager'" do
          before do
            procedure_presentation.update!(
              suivis_filters: [
                FilteredColumn.new(
                  column: procedure.dossier_notifications_column,
                  filter: "dossier_modifie"
                ),
              ]
            )
          end

          it "refesh DossierColumn to obtain correct options_for_select" do
            expect { process }.to change { procedure_presentation.suivis_filters }
          end

          it "does not change notification_type filter" do
            expect { process }.not_to change { procedure_presentation.suivis_filters.map(&:to_json) }
          end
        end

        context "which is 'message_usager'" do
          before do
            procedure_presentation.update!(
              suivis_filters: [
                FilteredColumn.new(
                  column: procedure.dossier_notifications_column,
                  filter: "message_usager"
                ),
              ]
            )
          end

          it "refesh DossierColumn to obtain correct options_for_select" do
            expect { process }.to change { procedure_presentation.suivis_filters }
          end

          it "updates filter to 'message'" do
            subject
            expect(procedure_presentation.suivis_filters.first.column).to eq(procedure.dossier_notifications_column)
            expect(procedure_presentation.suivis_filters.first.filter).to eq('message')
          end
        end
      end
    end
  end
end
