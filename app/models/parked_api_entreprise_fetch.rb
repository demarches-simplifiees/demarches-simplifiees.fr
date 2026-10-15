# frozen_string_literal: true

class ParkedAPIEntrepriseFetch < ApplicationRecord
  belongs_to :etablissement
  belongs_to :procedure

  DAILY_RETRIES = 3

  def self.park!(etablissement_id:, job:, procedure_id:, arguments:, code:, retried_daily: false)
    now = Time.current
    upsert(
      { etablissement_id:, job:, procedure_id:, arguments: ActiveJob::Arguments.serialize(arguments), code:, daily_failures: (1 if retried_daily), attempts: 1, created_at: now, updated_at: now },
      unique_by: [:etablissement_id, :job],
      on_duplicate: Arel.sql(<<~SQL.squish)
        attempts = parked_api_entreprise_fetches.attempts + 1,
        daily_failures = EXCLUDED.daily_failures + COALESCE(parked_api_entreprise_fetches.daily_failures, 0),
        code = EXCLUDED.code,
        procedure_id = EXCLUDED.procedure_id,
        arguments = EXCLUDED.arguments,
        enqueued_at = NULL,
        updated_at = EXCLUDED.updated_at
      SQL
    )
  end

  def self.release!(etablissement_id:, job:)
    where(etablissement_id:, job:).delete_all
  end

  def job_arguments = ActiveJob::Arguments.deserialize(arguments)
end
