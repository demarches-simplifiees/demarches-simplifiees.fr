# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_procedure_defaut_groupe_instructeur'
  task backfill_procedure_defaut_groupe_instructeur: :environment do
    puts "Running deploy task 'backfill_procedure_defaut_groupe_instructeur'"

    # rubocop:disable DS/Unscoped
    progress = ProgressReport.new(Procedure.unscoped.where(defaut_groupe_instructeur_id: nil).count)

    Procedure.unscoped.where(defaut_groupe_instructeur: nil).find_each do |p|
      p.defaut_groupe_instructeur = p.groupe_instructeurs.find { |g| g.label == "défaut" } || p.groupe_instructeurs.first
      p.save
      progress.inc
    end
    # rubocop:enable DS/Unscoped

    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
