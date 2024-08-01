# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: purge_motivation_dossiers_not_termine'
  task purge_motivation_dossiers_not_termine: :environment do
    puts "Running deploy task 'purge_motivation_dossiers_not_termine'"

    dossier_with_justificatif_motivation_ids = ActiveStorage::Attachment.where(name: 'justificatif_motivation').pluck(:record_id).uniq
    dossiers = Dossier.where(id: dossier_with_justificatif_motivation_ids).state_not_termine
    progress = ProgressReport.new(dossiers.count)

    dossiers.find_each do |dossier|
      dossier.justificatif_motivation.purge_later
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
