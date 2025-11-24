# frozen_string_literal: true

# Subscriber for LLM call notifications
ActiveSupport::Notifications.subscribe("llm.call") do |_name, start, finish, _id, payload|
  logger = Lograge.logger || Rails.logger

  payload[:duration_ms] = ((finish - start) * 1000).round
  payload[:timestamp] = Time.current.iso8601

  if payload[:exception]
    payload[:event] = "llm_call_error"
    payload[:error_class] = payload[:exception].class.name
    payload[:error_message] = payload[:exception].message
  else
    payload[:event] = "llm_call_success"
  end

  logger.info(payload.compact.to_json)
end
