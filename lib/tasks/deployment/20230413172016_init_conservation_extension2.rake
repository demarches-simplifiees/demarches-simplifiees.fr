# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: initialize conservation extension'
  task init_conservation_extension2: :environment do
    puts "Running deploy task 'init_conservation_extension'"

    changed = Dossier.where(conservation_extension: nil).update_all(conservation_extension: 0.days)
    puts "#{changed} dossiers were updated"

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
