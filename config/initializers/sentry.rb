Sentry.init do |config|
  secrets = Rails.application.secrets.sentry

  config.dsn = secrets[:enabled] ? secrets[:rails_client_key] : nil
  config.send_default_pii = false
  config.environment = secrets[:environment] || Rails.env
  config.enabled_environments = ['production', secrets[:environment].presence].compact
  config.breadcrumbs_logger = [:active_support_logger]
  config.traces_sample_rate = secrets[:enabled] ? 0.001 : nil
  config.delayed_job.report_after_job_retries = true
end
