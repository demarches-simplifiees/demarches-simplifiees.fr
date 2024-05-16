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
    transaction_context = sampling_context[:transaction_context]

    # transaction_context helps you sample transactions with more sophistication
    # for example, you can provide different sample rates based on the operation or name
    case transaction_context[:op]
    when /delayed_job/
      contexts = Sentry.get_current_scope.contexts
      job_class = contexts.dig(:"Active-Job", :job_class)
      attempts = contexts.dig(:"Delayed-Job", :attempts)
      max_attempts = job_class.safe_constantize&.new&.max_attempts rescue 25

      # Don't trace on all attempts
      [0, 2, 5, 10, 20, max_attempts].include?(attempts)
    else # rails requests
      if sampling_context.dig(:env, "REQUEST_METHOD") == "GET"
        0.001
      else
        0.01
      end
    end
  end

  config.delayed_job.report_after_job_retries = false # don't wait for all attempts before reporting
end
