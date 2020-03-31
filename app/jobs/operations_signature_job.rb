class OperationsSignatureJob < CronJob
  self.cron_expression = "0 6 * * *"

  def perform(*args)
    last_midnight = Time.zone.today.beginning_of_day
    operations_by_day = BillSignatureService.grouped_unsigned_operation_until(last_midnight)
    operations_by_day.each do |day, operations|
      begin
        BillSignatureService.sign_operations(operations, day)
      rescue
        raise # let errors show up on Sentry and delayed_jobs
      end
    end
  end
end
