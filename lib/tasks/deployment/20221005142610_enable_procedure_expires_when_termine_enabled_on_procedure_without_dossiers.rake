namespace :after_party do
  desc 'Deployment task: enable_procedure_expires_when_termine_enabled_on_procedure_without_dossiers'
  task enable_procedure_expires_when_termine_enabled_on_procedure_without_dossiers: :environment do
    puts "Running deploy task 'enable_procedure_expires_when_termine_enabled_on_procedure_without_dossiers'"

    # Put your task implementation HERE.
    procedure_without_expiration = Procedure.where(procedure_expires_when_termine_enabled: false)
    progress = ProgressReport.new(procedure_without_expiration.count)
    procedure_without_expiration.find_each do |procedure|
      if procedure.dossiers.count.zero?
        procedure.update(procedure_expires_when_termine_enabled: true)
      end
      progress.inc
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
