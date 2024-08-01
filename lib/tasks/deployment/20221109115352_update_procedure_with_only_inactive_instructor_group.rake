# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: update_procedure_with_only_inactive_instructor_group'
  task update_procedure_with_only_inactive_instructor_group: :environment do
    puts "Running deploy task 'update_procedure_with_only_inactive_instructor_group'"

    # Put your task implementation HERE.
    Procedure.all.filter do |p|
      p.groupe_instructeurs.actif.count == 0
    end.each do |p|
      p.groupe_instructeurs.first.update(closed: false)
    end
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
