class OperationsSignatureJob < ApplicationJob
  queue_as :cron

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
