# frozen_string_literal: true

class Cron::EnableProcedureExpiresWhenTermineEnabledJob < Cron::CronJob
  self.schedule_expression = Expired.schedule_at(self)
  discard_on StandardError

  def perform(*args)
    return if ENV['ENABLE_PROCEDURE_EXPIRES_WHEN_TERMINE_ENABLED_JOB_LIMIT'].blank?
    Procedure.where(procedure_expires_when_termine_enabled: false)
      .limit(ENV['ENABLE_PROCEDURE_EXPIRES_WHEN_TERMINE_ENABLED_JOB_LIMIT'])
      .order(created_at: :desc)
      .update_all(procedure_expires_when_termine_enabled: true)
  end
end
