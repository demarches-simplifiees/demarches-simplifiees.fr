# frozen_string_literal: true

# Subscriber for LLM call notifications
ActiveSupport::Notifications.subscribe("llm.call") do |_name, start, finish, _id, payload|
  duration = finish - start
  event_type = payload[:exception] ? "llm_call_error" : "llm_call_success"

  logger = Lograge.logger || Rails.logger

  logger.info(payload.slice(
    :procedure_id,
    :rule,
    :action,
    :user_id,
    :model,
    :messages_count,
    :prompt_tokens,
    :completion_tokens,
    :status,
    :error_class,
    :error_message
  ).merge(
    event: event_type,
    duration_ms: (duration * 1000).round,
    timestamp: Time.current.iso8601
  ).compact.to_json)
end
