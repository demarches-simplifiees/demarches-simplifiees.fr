# frozen_string_literal: true

class Cron::PurgeOrphanReferentielsJob < Cron::CronJob
  self.schedule_expression = "every week at 4:00"

  def perform
    referentiel_ids = TypeDeChamp.select(:referentiel_id).where.not(referentiel_id: nil).distinct.pluck(:referentiel_id)

    Referentiel.where.not(id: referentiel_ids)&.find_each(&:destroy)
  end
end
