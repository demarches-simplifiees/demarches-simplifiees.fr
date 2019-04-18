class TimestampJob < ApplicationJob
  queue_as :cron

  def perform
    Timestamp.create(period: 1.day.ago.beginning_of_day..1.day.ago.end_of_day)
  end
end
