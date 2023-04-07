namespace :after_party do
  desc 'Deployment task: back_fill_procedure_defaut_groupe_instructeur_id'
  task back_fill_procedure_defaut_groupe_instructeur_id: :environment do
    puts "Running deploy task 'back_fill_procedure_defaut_groupe_instructeur_id'"

    # Put your task implementation HERE.
    #

    # rubocop:disable DS/Unscoped
    progress = ProgressReport.new(Procedure.unscoped.where(defaut_groupe_instructeur_id: nil).count)

    Procedure.unscoped.where(defaut_groupe_instructeur_id: nil).find_each do |p|
      p.update_columns(defaut_groupe_instructeur_id: p.defaut_groupe_instructeur.id)
      progress.inc
    end
    # rubocop:enable DS/Unscoped

    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
