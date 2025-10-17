# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20251017SetDefaultFiltersForAllProcedurePresentationsTask do
    describe "#process" do
      let(:procedure) { create(:procedure) }
      let(:instructeur) { create(:instructeur) }
      let(:assign_to) { create(:assign_to, procedure: procedure, instructeur: instructeur) }
      let(:procedure_presentation) { create(:procedure_presentation, assign_to: assign_to) }

      subject(:process) { described_class.process(procedure_presentation) }

      context "when filters are blank" do
        before do
          ProcedurePresentation::ALL_FILTERS.each do |filter_attr|
            procedure_presentation.update_column(filter_attr, [])
          end
        end

        it "sets default filters for all statuts" do
          ProcedurePresentation::ALL_FILTERS.each do |filter_attr|
            expect(procedure_presentation.send(filter_attr)).to be_blank
          end

          subject

          procedure_presentation.reload

          ProcedurePresentation::ALL_FILTERS.each do |filter_attr|
            expect(procedure_presentation.send(filter_attr).count).to eq(3)
            expect(procedure_presentation.send(filter_attr).map(&:column).map(&:column)).to match_array(['state', 'id', 'notification_type'])
            expect(procedure_presentation.send(filter_attr).map(&:filter)).to all(eq({ operator: 'match', value: [] }))
          end
        end
      end

      context "when filters already exist" do
        let(:existing_filter) do
          FilteredColumn.new(
            column: procedure.find_column(label: 'Demandeur'),
            filter: { operator: 'match', value: ['test'] }
          )
        end

        before do
          procedure_presentation.update!(suivis_filters: [existing_filter])
        end

        it "does not override existing filters" do
          subject

          procedure_presentation.reload

          expect(procedure_presentation.suivis_filters.length).to eq(1)
          expect(procedure_presentation.suivis_filters.first.filter).to eq({ operator: 'match', value: ['test'] })
        end
      end
    end
  end
end
