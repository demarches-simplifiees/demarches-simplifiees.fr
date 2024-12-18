# frozen_string_literal: true

class Cron::PurgeOrphanReferentielsJob < Cron::CronJob
  self.schedule_expression = "every week at 4:00"

  def perform
    referentiel_ids = TypeDeChamp.pluck(:referentiel_id).compact.uniq

    Referentiel.where.not(id: referentiel_ids)&.find_each(&:destroy)
  end
end
