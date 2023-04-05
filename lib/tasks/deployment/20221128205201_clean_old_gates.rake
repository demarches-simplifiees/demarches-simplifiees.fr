namespace :after_party do
  desc 'Deployment task: clean_old_gates'
  task clean_old_gates: :environment do
    puts "Running deploy task 'clean_old_gates'"

    [
      'procedure_revisions',
      'instructeur_bypass_email_login_token',
      'procedure_conditional',
      'admin_affect_experts_to_avis'
    ].each do |key|
      Flipper::Adapters::ActiveRecord::Gate.where(feature_key: key).destroy_all
    end

    # Put your task implementation HERE.

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
