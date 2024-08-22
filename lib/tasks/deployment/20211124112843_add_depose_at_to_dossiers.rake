# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: add_depose_at_to_dossiers'
  task add_depose_at_to_dossiers: :environment do
    puts "Running deploy task 'add_depose_at_to_dossiers'"

    dossiers = Dossier.includes(:traitements).where(depose_at: nil).where.not(en_construction_at: nil)
    progress = ProgressReport.new(dossiers.count)

    dossiers.find_each do |dossier|
      traitement = dossier.traitements.find { |traitement| traitement.state == :en_construction }
      depose_at = traitement&.processed_at || dossier.en_construction_at
      dossier.update_column(:depose_at, depose_at)
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
