namespace :after_party do
  desc 'Deployment task: serialize_operation_log_authors'
  task serialize_operation_log_authors: :environment do
    puts "Running deploy task 'serialize_operation_log_authors'"

    dossier_operation_log = DossierOperationLog.where(payload: nil)
    progress = ProgressReport.new(dossier_operation_log.count)
    dossier_operation_log.find_each do |log|
      if log.automatic_operation
        log.author = nil
      elsif log.gestionnaire
        log.author = DossierOperationLog.serialize_author(log.gestionnaire)
      elsif log.administration
        log.author = DossierOperationLog.serialize_author(log.administration)
      end
      log.operation_date = log.created_at.iso8601
      log.save
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190411145806'
  end
end
