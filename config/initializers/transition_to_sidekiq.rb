# frozen_string_literal: true

if Rails.env.production? && SIDEKIQ_ENABLED
  ActiveSupport.on_load(:after_initialize) do
    [
      ActiveStorage::AnalyzeJob,
      ActiveStorage::PurgeJob,
      AdminUpdateDefaultZonesJob,
      APIEntreprise::Job,
      AdminUpdateDefaultZonesJob,
      BatchOperationEnqueueAllJob,
      BatchOperationProcessOneJob,
      ChampFetchExternalDataJob,
      Cron::CronJob,
      DestroyRecordLaterJob,
      DossierIndexSearchTermsJob,
      DossierOperationLogMoveToColdStorageBatchJob,
      DossierRebaseJob,
      HelpscoutCreateConversationJob,
      ImageProcessorJob,
      MaintenanceTasks::TaskJob,
      Migrations::BackfillStableIdJob,
      PriorizedMailDeliveryJob,
      ProcedureExternalURLCheckJob,
      ProcedureSVASVRProcessDossierJob,
      ProcessStalledDeclarativeDossierJob,
      ResetExpiringDossiersJob,
      SendClosingNotificationJob,
      VirusScannerJob,
      WebHookJob
    ].each do |job_class|
      job_class.queue_adapter = :sidekiq
    end
  end
end
