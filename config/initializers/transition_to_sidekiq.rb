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

    class WebHookJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class DestroyRecordLaterJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class ChampFetchExternalDataJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class DossierIndexSearchTermsJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class Migrations::BackfillStableIdJob
      self.queue_adapter = :sidekiq
    end

    class Cron::CronJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class APIEntreprise::Job < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class DossierOperationLogMoveToColdStorageBatchJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class BatchOperationEnqueueAllJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class BatchOperationProcessOneJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class TitreIdentiteWatermarkJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class AdminUpdateDefaultZonesJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class ProcessStalledDeclarativeDossierJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class ResetExpiringDossiersJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end

    class SendClosingNotificationJob < ApplicationJob
      self.queue_adapter = :sidekiq
    end
  end
end
