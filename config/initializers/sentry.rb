Sentry.init do |config|
  secrets = Rails.application.secrets.sentry

  config.dsn = secrets[:enabled] ? secrets[:rails_client_key] : nil
  config.send_default_pii = false
  config.environment = secrets[:environment] || Rails.env
  config.enabled_environments = ['production', secrets[:environment].presence].compact
  config.breadcrumbs_logger = [:active_support_logger]
  config.traces_sample_rate = secrets[:enabled] ? 0.001 : nil
  config.excluded_exceptions += [
    # Ignore exceptions caught by ActiveJob.retry_on
    # https://github.com/getsentry/sentry-ruby/issues/1347
    'Excon::Error::BadRequest',
    'ActiveStorage::IntegrityError',
    'VirusScannerJob::FileNotAnalyzedYetError',
    'TitreIdentiteWatermarkJob::WatermarkFileNotScannedYetError',
    'APIEntreprise::API::Error::TimedOut'
  ]
end
