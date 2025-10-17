# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20251010migrateInOperatorToMatchTask do
    describe "#process" do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :drop_down_list, libelle: 'Votre ville', options: ['Paris', 'Lyon', 'Marseille'] }]) }
      let(:instructeur) { create(:instructeur) }
      let(:assign_to) { create(:assign_to, procedure: procedure, instructeur: instructeur) }
      let(:procedure_presentation) { create(:procedure_presentation, assign_to: assign_to) }
      let(:column) { procedure.find_column(label: 'Votre ville') }
      let(:date_column) { procedure.find_column(label: 'Date de création') }

      subject(:process) { described_class.process(procedure_presentation) }

      context "when filters use 'in' operator" do
        before do
          procedure_presentation.update!(
            tous_filters: [
              FilteredColumn.new(column: column, filter: { operator: 'in', value: ['Paris', 'Lyon'] })
            ],
            suivis_filters: [
              FilteredColumn.new(column: column, filter: { operator: 'in', value: ['Marseille'] }),
              FilteredColumn.new(column: column, filter: { operator: 'match', value: ['Paris', 'Marseille'] })
            ],
            archives_filters: [
              FilteredColumn.new(column: date_column, filter: { operator: 'before', value: ['2025-01-01'] })
            ]
          )
        end

        it "migrates 'in' operator to 'match' filters" do
          subject
          expect(procedure_presentation.reload.tous_filters.first.filter).to eq({ operator: 'match', value: ['Paris', 'Lyon'] })
          expect(procedure_presentation.reload.suivis_filters.first.filter).to eq({ operator: 'match', value: ['Marseille'] })
          expect(procedure_presentation.reload.suivis_filters.second.filter).to eq({ operator: 'match', value: ['Paris', 'Marseille'] })
          expect(procedure_presentation.reload.archives_filters.first.filter).to eq({ operator: 'before', value: ['2025-01-01'] })
        end
      end

      context "when mixing 'in' and other operators" do
        let(:date_column) { procedure.find_column(label: 'Date de création') }

        before do
          procedure_presentation.update!(
            tous_filters: [
              FilteredColumn.new(column: column, filter: { operator: 'in', value: ['Paris'] }),
              FilteredColumn.new(column: date_column, filter: { operator: 'before', value: ['2025-01-01'] })
            ]
          )
        end

        it "only migrates 'in' operator" do
          subject
          filters = procedure_presentation.reload.tous_filters
          expect(filters[0].filter).to eq({ operator: 'match', value: ['Paris'] })
          expect(filters[1].filter).to eq({ operator: 'before', value: ['2025-01-01'] })
        end
      end
    end
  end
end
