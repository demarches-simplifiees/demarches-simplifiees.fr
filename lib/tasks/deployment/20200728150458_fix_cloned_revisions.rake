# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_cloned_revisions'
  task fix_cloned_revisions: :environment do
    puts "Running deploy task 'fix_cloned_revisions'"

    Procedure.with_discarded.where(aasm_state: :brouillon).where.not(published_revision_id: nil).update_all(published_revision_id: nil)

    begin
      types_de_champ = TypeDeChamp.joins(:revision).where('types_de_champ.procedure_id != procedure_revisions.procedure_id')
      progress = ProgressReport.new(types_de_champ.count)

      types_de_champ.find_each do |type_de_champ|
        procedure = type_de_champ.procedure ? type_de_champ.procedure : Procedure.with_discarded.find(type_de_champ.procedure_id)
        revision_id = procedure.published_revision_id || procedure.draft_revision_id
        type_de_champ.update_column(:revision_id, revision_id)
        progress.inc
      end

      progress.finish
    rescue ActiveRecord::StatementInvalid, PG::UndefinedColumn => e
      warn e.message
      puts "Skip deploy task."
    ensure
      # Update task as completed.  If you remove the line below, the task will
      # run with every deploy (or every time you call after_party:run).
      AfterParty::TaskRecord
        .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
    end
  end
end
