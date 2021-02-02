Sentry.init do |config|
  config.dsn = ENV['SENTRY_ENABLED'] == 'enabled' ? ENV['SENTRY_DSN_RAILS'] : nil
  config.send_default_pii = false
  config.enabled_environments = ['production']
  config.breadcrumbs_logger = [:active_support_logger]
end
