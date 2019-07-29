namespace :after_party do
  desc 'Deployment task: create_dummy_paths_for_archived_and_hidden_procedures'
  task create_dummy_paths_for_archived_and_hidden_procedures: :environment do
    puts "Running deploy task 'create_dummy_paths_for_archived_procedures'"

    Procedure.unscoped.archivees.where(path: nil).each do |p|
      p.update_column(:path, SecureRandom.uuid)
    end

    Procedure.unscoped.hidden.where(path: nil).each do |p|
      p.update_column(:path, SecureRandom.uuid)
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190704133852'
  end
end
