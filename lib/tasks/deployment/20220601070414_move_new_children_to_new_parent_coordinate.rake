# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: move_new_children_to_new_parent_coordinate'
  task move_new_children_to_new_parent_coordinate: :environment do
    puts "Running deploy task 'move_new_children_to_new_parent_coordinate'"

    children = ProcedureRevisionTypeDeChamp
      .includes(parent: :type_de_champ)
      .where.not(parent_id: nil)
      .filter { |child| child.revision_id != child.parent.revision_id }

    progress = ProgressReport.new(children.size)

    children.each do |child|
      new_parent = child.revision.revision_types_de_champ.joins(:type_de_champ).find_by!(type_de_champ: { stable_id: child.parent.stable_id })
      child.update!(parent: new_parent)
      progress.inc
    end

    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
