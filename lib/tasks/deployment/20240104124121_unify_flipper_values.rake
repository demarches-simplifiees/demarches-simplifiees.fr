namespace :after_party do
  desc 'Deployment task: unify_flipper_values'
  task unify_flipper_values: :environment do
    puts "Running deploy task 'unify_flipper_values'"

    Flipper::Adapters::ActiveRecord::Gate.all.each do |flipper_gate|
      if flipper_gate.value != flipper_gate.value.sub(':', ';')
        flipper_gate.destroy
      end
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
