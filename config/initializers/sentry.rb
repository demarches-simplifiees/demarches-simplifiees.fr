Sentry.init do |config|
  config.dsn = ENV['SENTRY_ENABLED'] == 'enabled' ? ENV['SENTRY_DSN_RAILS'] : nil
  config.send_default_pii = false
  config.environment = ENV.fetch('SENTRY_ENVIRONMENT', Rails.env)
  config.enabled_environments = ['production', ENV['SENTRY_ENVIRONMENT'].presence].compact
  config.breadcrumbs_logger = [:active_support_logger]
  config.traces_sample_rate = ENV['SENTRY_ENABLED'] == 'enabled' ? 0.001 : nil
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
