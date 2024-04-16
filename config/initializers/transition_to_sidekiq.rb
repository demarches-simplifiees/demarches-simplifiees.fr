sidekiq_enabled = ENV.has_key?('REDIS_SIDEKIQ_SENTINELS') || ENV.has_key?('REDIS_URL')

if Rails.env.production? && sidekiq_enabled
  ActiveSupport.on_load(:after_initialize) do
    class ActiveStorage::PurgeJob < ActiveStorage::BaseJob
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
  end
end
