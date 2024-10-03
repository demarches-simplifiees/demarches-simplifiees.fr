# frozen_string_literal: true

Sentry.init do |config|
  secrets = Rails.application.secrets.sentry

  if ENV['http_proxy'].present?
    config.transport.proxy = ENV['http_proxy']
  end

  config.dsn = secrets[:enabled] ? secrets[:rails_client_key] : nil
  config.send_default_pii = false
  config.release = ApplicationVersion.current
  config.environment = secrets[:environment] || Rails.env
  config.enabled_environments = ['production', secrets[:environment].presence].compact
  config.breadcrumbs_logger = [:active_support_logger]
  config.traces_sampler = lambda do |sampling_context|
    # if this is the continuation of a trace, just use that decision (rate controlled by the caller)
    unless sampling_context[:parent_sampled].nil?
      next sampling_context[:parent_sampled]
    end

    # transaction_context is the transaction object in hash form
    # keep in mind that sampling happens right after the transaction is initialized
    # for example, at the beginning of the request
    if sampling_context[:transaction_context].dig(:env, "REQUEST_METHOD") == "GET"
      0.001
    else
      0.01
    end
  end
end
