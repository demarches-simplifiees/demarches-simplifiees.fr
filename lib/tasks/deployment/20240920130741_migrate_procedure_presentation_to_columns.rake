# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: migrate_procedure_presentation_to_columns'
  task migrate_procedure_presentation_to_columns: :environment do
    total = ProcedurePresentation.count

    progress = ProgressReport.new(total)

    ProcedurePresentation.find_each do |presentation|
      procedure_id = presentation.procedure.id

      presentation.displayed_columns = presentation.displayed_fields
        .compact_blank
        .map { Column.new(**_1.deep_symbolize_keys.merge(procedure_id:)) }
        .map(&:h_id)

      sort = presentation.sort

      presentation.sorted_column = {
        'order' => sort['order'],
        'id' => make_id(procedure_id, sort['table'], sort['column'])
      }

      presentation.filters.each do |key, filters|
        raw_columns = filters.map do
          {
            id: make_id(procedure_id, _1['table'], _1['column']),
            filter: _1['value']
          }
        end

        presentation.send("#{presentation.filters_name_for(key)}=", raw_columns)
      end

      presentation.save!(validate: false)
      progress.inc
    end

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end

  private

  def make_id(procedure_id, table, column)
    { procedure_id:, column_id: "#{table}/#{column}" }
  end
end
