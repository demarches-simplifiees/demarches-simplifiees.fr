# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250115RefreshColumnsIdInProcedurePresentationTask do
    def displayed_column_ids
      raw = ProcedurePresentation
        .connection
        .select_value('SELECT array_to_json(displayed_columns) from procedure_presentations')

      JSON.parse(raw).map { _1['column_id'] }
    end

    def a_suivre_column_id
      raw = ProcedurePresentation
        .connection
        .select_value('SELECT array_to_json(a_suivre_filters) from procedure_presentations')
        .then { JSON.parse(_1).first }

      raw['id']['column_id']
    end

    describe "#process" do
      subject(:process) { described_class.process(ProcedurePresentation.find(procedure_presentation.id)) }

      let(:instructeur) { create(:instructeur) }
      let(:procedure_presentation) do
        groupe_instructeur = procedure.defaut_groupe_instructeur
        assign_to = create(:assign_to, instructeur:, groupe_instructeur:)
        assign_to.procedure_presentation_or_default_and_errors.first
      end

      describe "#old_linked_drop_down?" do
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :linked_drop_down_list, libelle: 'linked' }]) }

        let(:old_syntaxed_columns) do
          procedure.columns.filter { _1.label =~ /linked/ }.map do |column|
            def column.h_id
              original_h_id = super()
              original_h_id[:column_id] = original_h_id[:column_id].gsub('.', '->')
              original_h_id
            end

            column
          end
        end

        before do
          procedure_presentation.update(displayed_columns: old_syntaxed_columns)
          procedure_presentation.update(a_suivre_filters: [FilteredColumn.new(column: old_syntaxed_columns.first, filter: 'filter')])

          # destroy the columns cache
          Current.procedure_columns = nil
        end

        it do
          # ensure old syntax is present in db
          expect(displayed_column_ids.any? { _1.include?('->') }).to be(true)
          expect(a_suivre_column_id).to include('->')

          process

          expect(displayed_column_ids.any? { _1.include?('->') }).to be(false)
          expect(a_suivre_column_id).not_to include('->')
        end
      end

      describe "#department_columns" do
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :address, libelle: 'address' }]) }
        let(:old_department) do
          department_column = procedure.columns.filter { _1.id =~ /\$.department/ }.first

          def department_column.h_id
            original_h_id = super()
            original_h_id[:column_id] = original_h_id[:column_id].gsub('department', 'departement')
            original_h_id
          end

          department_column
        end

        before do
          procedure_presentation.update(displayed_columns: [old_department])

          # destroy the columns cache
          Current.procedure_columns = nil
        end

        it do
          # ensure old syntax is present in db
          expect(displayed_column_ids.any? { _1.include?('departement') }).to be(true)

          process

          expect(displayed_column_ids.any? { _1.include?('departement') }).to be(false)
        end
      end
    end
  end
end
