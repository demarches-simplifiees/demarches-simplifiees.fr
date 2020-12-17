namespace :after_party do
  desc 'Deployment task: migrate_filters_to_use_stable_id'
  task migrate_filters_to_use_stable_id: :environment do
    puts "Running deploy task 'migrate_filters_to_use_stable_id'"

    procedure_presentations = ProcedurePresentation.where("filters -> 'migrated' IS NULL")
    progress = ProgressReport.new(procedure_presentations.count)
    procedure_presentations.find_each do |procedure_presentation|
      filters = procedure_presentation.filters
      sort = procedure_presentation.sort

      ['tous', 'suivis', 'traites', 'a-suivre', 'archives'].each do |statut|
        filters[statut] = filters[statut].map do |filter|
          table, column, value = filter.values_at('table', 'column', 'value')
          if table && (table == 'type_de_champ' || table == 'type_de_champ_private')
            type_de_champ = TypeDeChamp.find_by(id: column)
            if type_de_champ
              column = type_de_champ.stable_id
            end
          end
          [table, column, value]
        end
      end

      table, column = sort.values_at('table', 'column')
      if table && (table == 'type_de_champ' || table == 'type_de_champ_private')
        type_de_champ = TypeDeChamp.find_by(id: column)
        if type_de_champ
          sort['column'] = type_de_champ.stable_id
        end
      end

      filters['migrated'] = true
      procedure_presentation.update_columns(filters: filters, sort: sort)
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
