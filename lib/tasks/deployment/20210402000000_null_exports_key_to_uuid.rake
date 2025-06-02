# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: null_exports_key_to_uuid'
  task null_exports_key_to_uuid: :environment do
    puts "Running deploy task 'null_exports_key_to_uuid'"

    Export.where(key: nil).update_all(key: SecureRandom.uuid)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
