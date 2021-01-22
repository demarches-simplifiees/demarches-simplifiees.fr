class Cron::OperationsSignatureJob < Cron::CronJob
  self.schedule_expression = "every day at 6 am"

  def perform(*args)
    last_midnight = Time.zone.now.beginning_of_day
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
