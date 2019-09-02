namespace :after_party do
  desc 'Deployment task: link_assign_and_groupe_instructeur'
  task link_assign_and_groupe_instructeur: :environment do
    AssignTo.find_each do |at|
      GroupeInstructeur
        .find_by(procedure_id: at.procedure_id)
        &.assign_tos
        &.push(at)
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190819145528'
  end
end
