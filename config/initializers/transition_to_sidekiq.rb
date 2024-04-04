SIDEKIQ_ENABLED = ENV.has_key?('REDIS_SIDEKIQ_SENTINELS') || ENV.has_key?('REDIS_URL')

if Rails.env.production? && SIDEKIQ_ENABLED
  ActiveSupport.on_load(:after_initialize) do
    class ActiveStorage::PurgeJob < ActiveStorage::BaseJob
      self.queue_adapter = :sidekiq
    end

    class ActiveStorage::AnalyzeJob < ActiveStorage::BaseJob
      self.queue_adapter = :sidekiq
    end

    class VirusScannerJob
      self.queue_adapter = :sidekiq
    end

    class DossierRebaseJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class ProcedureExternalURLCheckJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class MaintenanceTasks::TaskJob
      self.queue_adapter = :sidekiq
    end

    class PriorizedMailDeliveryJob < ActionMailer::MailDeliveryJob
      self.queue_adapter = :sidekiq
    end

    class ProcedureSVASVRProcessDossierJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class WebhookJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class DestroyRecordLaterJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class ChampFetchExternalDataJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class DossierUpdateSearchTermsJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end
  end
end
