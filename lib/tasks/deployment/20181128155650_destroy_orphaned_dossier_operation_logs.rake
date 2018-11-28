namespace :after_party do
  desc 'Deployment task: destroy_orphaned_dossier_operation_logs'
  task destroy_orphaned_dossier_operation_logs: :environment do
    bar = RakeProgressbar.new(DossierOperationLog.count)

    DossierOperationLog.find_each do |log|
      if log.dossier.blank?
        log.destroy
      end
      bar.inc
    end

    bar.finished

    AfterParty::TaskRecord.create version: '20181128155650'
  end
end
