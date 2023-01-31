namespace :after_party do
  desc 'Deployment task: fix_dossier_transfer_with_uppercase'
  task fix_dossier_transfer_with_uppercase: :environment do
    puts "Running deploy task 'fix_dossier_transfer_with_uppercase'"
    # in production, about 1000, no need to track progress

    DossierTransfer.all.find_each do |dt|
      if /A-Z/.match?(dt.email)
        dt.email = dt.email.downcase
        dt.save
      end
    end
    # Put your task implementation HERE.

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
