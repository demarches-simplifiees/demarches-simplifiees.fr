# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: unroute_cloned_procedures_from_diffent_admin'
  task unroute_cloned_procedures_from_diffent_admin: :environment do
    puts "Running deploy task 'unroute_cloned_procedures_from_diffent_admin'"

    # Put your task implementation HERE.
    Procedure
      .with_discarded
      .where(routing_enabled: true)
      .filter { |p| p.groupe_instructeurs.active.count == 1 }
      .each do |p|
        p.update!(routing_enabled: false)
      end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
