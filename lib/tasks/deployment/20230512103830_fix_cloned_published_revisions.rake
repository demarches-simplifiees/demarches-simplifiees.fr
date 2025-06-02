# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_cloned_published_revisions'
  task fix_cloned_published_revisions: :environment do
    puts "Running deploy task 'fix_cloned_published_revisions'"

    parent_procedures = Procedure
      .joins(:published_revision)
      .where('procedure_revisions.procedure_id != procedures.id')

    parent_procedures.find_each do |parent_procedure|
      cloned_procedures = Procedure
        .where(parent_procedure:)
        .includes(:revisions)
        .filter { parent_procedure.published_revision_id.in?(_1.revisions.ids) }

      cloned_procedures.each do |cloned_procedure|
        foreign_revision = cloned_procedure.revisions.find parent_procedure.published_revision_id
        new_revision = parent_procedure.create_new_revision(foreign_revision)

        cloned_groupe_instructeur_ids = cloned_procedure.groupe_instructeurs.ids
        cloned_procedure_dossiers, _ = cloned_procedure
          .dossiers
          .partition { _1.groupe_instructeur_id.in?(cloned_groupe_instructeur_ids) }

        if cloned_procedure.draft_revision_id == foreign_revision.id
          cloned_procedure.update(draft_revision: new_revision)
          puts "Update draft_revision for procedure #{cloned_procedure.id}"
        elsif cloned_procedure.published_revision_id == foreign_revision.id
          cloned_procedure.update(published_revision: new_revision)
          puts "Update published_revision for procedure #{cloned_procedure.id}"
        end
        cloned_procedure_dossiers.each { _1.update(revision_id: new_revision.id) }
        puts "Update dossiers #{cloned_procedure_dossiers.map(&:id)} for procedure: #{cloned_procedure.id}"

        foreign_revision.update(procedure_id: parent_procedure.id)

        puts "Update revision #{foreign_revision.id} for procedure: #{cloned_procedure.id}"
      end
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
