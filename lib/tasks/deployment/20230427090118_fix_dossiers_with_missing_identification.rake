# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_dossiers_with_missing_identification'
  task fix_dossiers_with_missing_identification: :environment do
    puts "Running deploy task 'fix_dossiers_with_missing_identification'"

    dossiers = Dossier
      .state_en_construction
      .joins(:procedure)
      .where(autorisation_donnees: nil)

    dossier_ids_without_etablissement = dossiers
      .where(procedure: { for_individual: false })
      .where.missing(:etablissement)
      .pluck('dossiers.id')

    dossier_ids_without_individual = dossiers
      .where(procedure: { for_individual: true })
      .pluck('dossiers.id')

    dossier_ids = dossier_ids_without_etablissement + dossier_ids_without_individual
    progress = ProgressReport.new(dossier_ids.size)

    rake_puts "Dossier ids without etablissement: #{dossier_ids_without_etablissement}"
    rake_puts "Dossier ids without individual: #{dossier_ids_without_individual}"

    Dossier.where(id: dossier_ids).in_batches do |relation|
      count = relation.count
      relation.update_all(state: Dossier.states.fetch(:brouillon), en_construction_at: nil, depose_at: nil)
      progress.inc(count)
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
