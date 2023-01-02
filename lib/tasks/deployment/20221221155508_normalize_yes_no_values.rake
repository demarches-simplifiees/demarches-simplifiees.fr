namespace :after_party do
  desc 'Deployment task: normalize_yes_no_values'
  task normalize_yes_no_values: :environment do
    puts "Running deploy task 'normalize_yes_no_values'"

    Champs::YesNoChamp.where(value: '').in_batches(of: 10_000) { |yes_no| yes_no.update_all(value: nil) }
    Champs::YesNoChamp.where.not(value: [nil, 'true', 'false']).in_batches(of: 10_000) { |yes_no| yes_no.update_all(value: 'false') }

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
