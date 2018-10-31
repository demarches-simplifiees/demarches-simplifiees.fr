namespace :after_party do
  desc 'Deployment task: remove_path_from_archived_procedures'
  task remove_path_from_archived_procedures: :environment do
    Procedure.archivees.where.not(path: nil).update_all(path: nil)

    AfterParty::TaskRecord.create version: '20181031104615'
  end
end
