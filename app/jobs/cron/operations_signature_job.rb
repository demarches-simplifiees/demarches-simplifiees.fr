class Cron::OperationsSignatureJob < Cron::CronJob
  self.schedule_expression = "every day at 06:00"

  def perform(*args)
    start_date = DossierOperationLog.where(bill_signature: nil).order(:executed_at).pick(:executed_at).beginning_of_day
    last_midnight = Time.zone.now.beginning_of_day

    while start_date < last_midnight
      operations = DossierOperationLog
        .select(:id, :digest)
        .where(executed_at: start_date...start_date.tomorrow, bill_signature: nil)

      BillSignatureService.sign_operations(operations, start_date) if operations.present?

      start_date = start_date.tomorrow
    end
  end
end
