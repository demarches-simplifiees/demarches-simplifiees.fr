# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: update_procedure_with_active_group_and_routing_nil'
  task update_procedure_with_active_group_and_routing_nil: :environment do
    puts "Running deploy task 'update_procedure_with_active_group_and_routing_nil'"

    # Put your task implementation HERE.
    Procedure.where(routing_enabled: nil).filter do |p|
      p.groupe_instructeurs.actif.count > 1
    end.each do |p|
      p.update(routing_enabled: true)
    end
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
