# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: clean_orphaned_targeted_user_links'
  task clean_orphaned_targeted_user_links: :environment do
    puts "Running deploy task 'clean_orphaned_targeted_user_links'"

    progress = ProgressReport.new(TargetedUserLink.count)
    TargetedUserLink.find_each do |tul|
      if tul.target_model.nil?
        tul.destroy
      end
      progress.inc
    end
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
