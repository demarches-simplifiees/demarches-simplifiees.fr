# frozen_string_literal: true

require Rails.root.join("lib", "tasks", "task_helper")

namespace :etablissement do
  desc 'Immediately consolidate etablissements in degraded mode for a given procedure id'
  task update_from_degraded_mode: :environment do
    procedure_id = ENV.fetch("PROCEDURE_ID")

    # Logic from BackfillSiretDegradedModeJob
    # but without the wait of all dossiers queue.

    rake_puts "Consolidate dossiers"
    etablissements = Etablissement.joins(dossier: :revision).where(adresse: nil, dossier: { procedure_revisions: { procedure_id: } })
    progress = ProgressReport.new(etablissements.count)

    etablissements.find_each do |etablissement|
      begin
        APIEntrepriseService.update_etablissement_from_degraded_mode(etablissement, procedure_id)
      rescue => e
        Sentry.capture_exception(e)
        rake_puts "Etablissement ##{etablissement.id}: #{e.message}"
      end

      progress.inc
    end
    progress.finish

    rake_puts "Consolidate champs SIRET"
    etablissements = Etablissement.joins(champ: { dossier: :revision }).where(adresse: nil, champ: { procedure_revisions: { procedure_id: } })
    progress = ProgressReport.new(etablissements.count)

    etablissements.find_each do |etablissement|
      begin
        APIEntrepriseService.update_etablissement_from_degraded_mode(etablissement, procedure_id)
      rescue => e
        Sentry.capture_exception(e)
        rake_puts "Etablissement ##{etablissement.id}: #{e.message}"
      end

      progress.inc
    end

    progress.finish
  end
end
