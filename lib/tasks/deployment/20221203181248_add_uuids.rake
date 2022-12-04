namespace :after_party do
  desc 'Deployment task: add_uuids'
  task add_uuids: :environment do
    puts "Running deploy task 'add_uuids'"

    users = User.where(uuid: nil)
    progress = ProgressReport.new(users.count)
    users.find_each do |user|
      user.update_column(:uuid, SecureRandom.uuid)
      progress.inc
    end
    progress.finish

    procedures = Procedure.with_discarded.where(uuid: nil)
    progress = ProgressReport.new(procedures.count)
    procedures.find_each do |procedure|
      procedure.update_column(:uuid, SecureRandom.uuid)
      progress.inc
    end
    progress.finish

    dossiers = Dossier.where(uuid: nil)
    progress = ProgressReport.new(dossiers.count)
    dossiers.find_each do |dossier|
      dossier.update_column(:uuid, SecureRandom.uuid)
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
