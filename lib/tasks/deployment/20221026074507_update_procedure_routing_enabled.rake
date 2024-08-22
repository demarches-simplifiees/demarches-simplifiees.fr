# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: update_procedure_routing_enabled'
  task update_procedure_routing_enabled: :environment do
    puts "Running deploy task 'update_procedure_routing_enabled'"

    # Put your task implementation HERE.
    Procedure.where(routing_enabled: true)
      .filter do |p|
        p.groupe_instructeurs.actif.count < 2
      end.each do |p|
        p.update(routing_enabled: false)
      end
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
