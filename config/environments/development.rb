Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Verifies that versions and hashed value of the package contents in the project's package.json
  config.webpacker.check_yarn_integrity = true

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.active_storage.service = ENV['FOG_ENABLED'] == 'enabled' ? :openstack : :local

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Action Mailer settings

  if ENV['SENDINBLUE_ENABLED'] == 'enabled'
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      user_name: Rails.application.secrets.sendinblue[:username],
      password: Rails.application.secrets.sendinblue[:smtp_key],
      address: 'smtp-relay.sendinblue.com',
      domain: 'smtp-relay.sendinblue.com',
      port: '587',
      authentication: :cram_md5
    }
  else
    config.action_mailer.delivery_method = :letter_opener_web
    config.action_mailer.default_url_options = {
      host: 'localhost',
      port: 3000
    }

    config.action_mailer.asset_host = "http://" + ENV['APP_HOST']
  end

  Rails.application.routes.default_url_options = {
    host: 'localhost',
    port: 3000
  }

  # Use Content-Security-Policy-Report-Only headers
  config.content_security_policy_report_only = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # This is useful to run rails in development with :async queue adapter
  if ENV['RAILS_QUEUE_ADAPTER']
    config.active_job.queue_adapter = ENV['RAILS_QUEUE_ADAPTER'].to_sym
  end

  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end
