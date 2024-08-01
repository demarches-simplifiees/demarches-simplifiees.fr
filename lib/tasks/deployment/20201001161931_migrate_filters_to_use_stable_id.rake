# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: migrate_filters_to_use_stable_id'
  task migrate_filters_to_use_stable_id: :environment do
    puts "Running deploy task 'migrate_filters_to_use_stable_id'"

    procedure_presentations = ProcedurePresentation.where("filters -> 'migrated' IS NULL")
    progress = ProgressReport.new(procedure_presentations.count)
    procedure_presentations.find_each do |procedure_presentation|
      filters = procedure_presentation.filters
      sort = procedure_presentation.sort
      displayed_fields = procedure_presentation.displayed_fields

      ['tous', 'suivis', 'traites', 'a-suivre', 'archives'].each do |statut|
        filters[statut] = filters[statut].map do |filter|
          table, column = filter.values_at('table', 'column')
          if table && (table == 'type_de_champ' || table == 'type_de_champ_private')
            type_de_champ = TypeDeChamp.find_by(id: column)
            filter['column'] = type_de_champ&.stable_id&.to_s
          end
          filter
        end
      end

      table, column = sort.values_at('table', 'column')
      if table && (table == 'type_de_champ' || table == 'type_de_champ_private')
        type_de_champ = TypeDeChamp.find_by(id: column)
        sort['column'] = type_de_champ&.stable_id&.to_s
      end

      displayed_fields = displayed_fields.map do |displayed_field|
        table, column = displayed_field.values_at('table', 'column')
        if table && (table == 'type_de_champ' || table == 'type_de_champ_private')
          type_de_champ = TypeDeChamp.find_by(id: column)
          displayed_field['column'] = type_de_champ&.stable_id&.to_s
        end
        displayed_field
      end

      filters['migrated'] = true
      procedure_presentation.update_columns(filters: filters, sort: sort, displayed_fields: displayed_fields)
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
