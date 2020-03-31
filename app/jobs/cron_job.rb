class CronJob < ApplicationJob
  queue_as :cron
  class_attribute :cron_expression

  class << self
    def schedule
      remove if cron_expression_changed?
      set(cron: cron_expression).perform_later if !scheduled?
    end

    def remove
      delayed_job.destroy if scheduled?
    end

    def scheduled?
      delayed_job.present?
    end

    def cron_expression_changed?
      scheduled? && delayed_job.cron != cron_expression
    end

    def delayed_job
      Delayed::Job
        .where('handler LIKE ?', "%job_class: #{name}%")
        .first
    end
  end
end
