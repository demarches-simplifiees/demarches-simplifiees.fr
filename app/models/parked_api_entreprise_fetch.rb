# frozen_string_literal: true

class ParkedAPIEntrepriseFetch < ApplicationRecord
  belongs_to :etablissement
  belongs_to :procedure

  def self.park!(etablissement_id:, job:, procedure_id:, arguments:, code:)
    now = Time.current
    upsert(
      { etablissement_id:, job:, procedure_id:, arguments: ActiveJob::Arguments.serialize(arguments), code:, attempts: 1, created_at: now, updated_at: now },
      unique_by: [:etablissement_id, :job],
      on_duplicate: Arel.sql(<<~SQL.squish)
        attempts = parked_api_entreprise_fetches.attempts + 1,
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
