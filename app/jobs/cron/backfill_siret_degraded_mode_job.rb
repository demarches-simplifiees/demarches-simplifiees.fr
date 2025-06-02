# frozen_string_literal: true

class Cron::BackfillSiretDegradedModeJob < Cron::CronJob
  self.schedule_expression = "every 2 hour"

  def perform(*args)
    fix_etablissement_with_dossier
    fix_etablissement_with_champs
  end

  def fix_etablissement_with_dossier
    Etablissement.joins(:dossier).where(adresse: nil).find_each do |etablissement|
      begin
        puts "Backfill siret for #{etablissement.siret} for dossier #{etablissement.dossier.id}"
        procedure_id = etablissement.dossier.procedure.id
        APIEntrepriseService.update_etablissement_from_degraded_mode(etablissement, procedure_id)
      rescue => e
        puts "Exception dans BackfillSiretDegradedMode: #{e.message}\n   #{e.backtrace.join('\n   ')}"
        Sentry.capture_exception(e)
      end
    end
  end

  def fix_etablissement_with_champs
    Etablissement.joins(:champ).where(adresse: nil).find_each do |etablissement|
      begin
        puts "Backfill siret for #{etablissement.siret} for champ #{etablissement.champ.libelle} in dossier #{etablissement.champ.dossier.id}"
        procedure_id = etablissement.champ.procedure.id

        APIEntrepriseService.update_etablissement_from_degraded_mode(etablissement, procedure_id)
      rescue => e
        puts "Exception dans BackfillSiretDegradedMode: #{e.message}\n   #{e.backtrace.join('\n   ')}"
        Sentry.capture_exception(e)
      end
    end
  end
end
