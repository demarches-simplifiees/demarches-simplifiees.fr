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
        graphql_query: event.payload[:graphql_query],
        graphql_variables: event.payload[:graphql_variables],
        graphql_null_error: event.payload[:graphql_null_error],
        graphql_timeout_error: event.payload[:graphql_timeout_error],
        ds_procedure_id: event.payload[:ds_procedure_id],
        ds_dossier_id: event.payload[:ds_dossier_id],
        browser: event.payload[:browser],
        browser_version: event.payload[:browser_version],
        platform: event.payload[:platform],
        client_ip: event.payload[:client_ip],
        request_id: event.payload[:request_id],
        process: {
          pid: Process.pid
        }
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
    ActiveJob::ApplicationLogSubscriber.attach_to(:active_job)
  end
end
