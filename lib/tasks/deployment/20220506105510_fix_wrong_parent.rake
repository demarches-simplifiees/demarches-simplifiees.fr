# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_wrong_parent'
  task fix_wrong_parent: :environment do
    children = ProcedureRevisionTypeDeChamp.where.not(parent_id: nil).includes(:parent)

    rake_puts "#{children.count} children to check"

    progress = ProgressReport.new(children.count)

    misconfigured = children.filter do |child|
      progress.inc
      child.revision_id != child.parent.revision_id
    end
    progress.finish

    rake_puts "#{misconfigured.count} children to fix"

    progress = ProgressReport.new(misconfigured.count)

    misconfigured.each do |child|
      new_parent = ProcedureRevisionTypeDeChamp.find_by(revision: child.revision, type_de_champ_id: child.parent.type_de_champ_id)
      child.update(parent_id: new_parent.id)
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
