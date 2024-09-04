# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_instructeurs_self_management_for_routed_procedures'
  task fix_instructeurs_self_management_for_routed_procedures: :environment do
    puts "Running deploy task 'fix_instructeurs_self_management_for_routed_procedures'"

    # Put your task implementation HERE.
    Procedure.with_discarded
      .where(routing_enabled: true)
      .where(instructeurs_self_management_enabled: [nil, false])
      .update_all(instructeurs_self_management_enabled: true)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
