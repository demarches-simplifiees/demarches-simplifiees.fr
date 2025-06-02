# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_types_de_champ_revisions'
  task fix_types_de_champ_revisions: :environment do
    puts "Running deploy task 'fix_types_de_champ_revisions'"

    types_de_champ = TypeDeChamp.joins(:parent).where('types_de_champ.revision_id != parents_types_de_champ.revision_id')
    progress = ProgressReport.new(types_de_champ.count)
    types_de_champ.find_each do |type_de_champ|
      type_de_champ.update_column(:revision_id, type_de_champ.parent.revision_id)
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
