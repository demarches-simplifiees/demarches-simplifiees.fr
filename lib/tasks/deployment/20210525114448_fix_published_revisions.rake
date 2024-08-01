# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_published_revisions'
  task fix_published_revisions: :environment do
    puts "Running deploy task 'fix_published_revisions'"

    procedure_ids = Procedure
      .with_discarded
      .joins(:revisions)
      .group('procedures.id')
      .having('count(procedure_id) > 2')
      .map(&:id)

    # Remove wrongfully created revisions. Every procedure should have only a draft revision
    # and a published revision for published procedure
    revisions = ProcedureRevision
      .joins(:procedure)
      .where(procedure_id: procedure_ids)
      .where('procedure_revisions.id != procedures.draft_revision_id AND procedure_revisions.id != procedures.published_revision_id')

    dossiers = Dossier.with_discarded.joins(:procedure).where(revision_id: revisions)
    progress = ProgressReport.new(dossiers.count)
    dossiers.find_each do |dossier|
      dossier.update_column(:revision_id, dossier.procedure.published_revision_id)
      progress.inc
    end
    progress.finish

    types_de_champ = TypeDeChamp.joins(:procedure).where(revision_id: revisions)
    progress = ProgressReport.new(types_de_champ.count)
    types_de_champ.find_each do |type_de_champ|
      type_de_champ.update_column(:revision_id, type_de_champ.procedure.published_revision_id)
      progress.inc
    end
    progress.finish

    ProcedureRevisionTypeDeChamp.where(revision_id: revisions).delete_all
    revisions.delete_all

    # Fill published_at column on all published revisions
    published_revisions = ProcedureRevision
      .joins(:procedure)
      .where(published_at: nil)
      .where('procedure_revisions.id = procedures.published_revision_id')
    progress = ProgressReport.new(published_revisions.count)
    published_revisions.find_each do |revision|
      revision.update_column(:published_at, revision.procedure.published_at)
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
