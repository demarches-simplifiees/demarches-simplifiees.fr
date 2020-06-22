class CronJob < ApplicationJob
  queue_as :cron
  class_attribute :schedule_expression

  class << self
    def schedule
      remove if cron_expression_changed?
      set(cron: cron_expression).perform_later if !scheduled?
    end

    def remove
      delayed_job.destroy if scheduled?
    end

    def display_schedule
      pp "#{name}: #{schedule_expression} cron(#{cron_expression})"
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

    def cron_expression
      Fugit.do_parse(schedule_expression, multi: :fail).to_cron_s
    end
  end
end
