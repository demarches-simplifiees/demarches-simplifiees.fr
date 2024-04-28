# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_procedure_instructeurs_self_management_enabled'
  task backfill_procedure_instructeurs_self_management_enabled: :environment do
    puts "Running deploy task 'backfill_procedure_instructeurs_self_management_enabled'"

    # Code below is commented because this after party has already been run
    # (the final lines which create version had been deleted by accident)

    # procedures = Procedure.unscoped.all
    # progress = ProgressReport.new(procedures.count)

    # Procedure.find_each do |procedure|
    #   procedure.update_column(:instructeurs_self_management_enabled, procedure.routing_enabled?)
    #   progress.inc(1)
    # end

    # progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
