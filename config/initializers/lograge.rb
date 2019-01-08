require_relative './active_job_log_subscriber'

Rails.application.configure do
  config.lograge.formatter = Lograge::Formatters::Logstash.new
  config.lograge.base_controller_class = ['ActionController::Base', 'Manager::ApplicationController']

  # This will allow to override custom options from environement file
  # injected by ansible.
  if !config.lograge.custom_options
    config.lograge.custom_options = lambda do |event|
      {
        type: 'tps',
        source: ENV['SOURCE'],
        tags: ['request', event.payload[:exception] ? 'exception' : nil].compact,
        user_id: event.payload[:user_id],
        user_email: event.payload[:user_email],
        user_roles: event.payload[:user_roles],
        user_agent: event.payload[:user_agent],
        browser: event.payload[:browser],
        browser_version: event.payload[:browser_version],
        platform: event.payload[:platform]
      }.compact
    end

    config.lograge.custom_payload do |controller|
      {
        xhr: !!controller&.request&.xhr?
      }
    end
  end

  config.lograge.keep_original_rails_log = true
  config.lograge.logger = ActiveSupport::Logger.new(Rails.root.join('log', "logstash_#{Rails.env}.log"))

  if config.lograge.enabled
    ActiveJobLogSubscriber.attach_to(:active_job)
  end
end
