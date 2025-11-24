# frozen_string_literal: true

require 'json'
require 'uri'

module LLM
  class Runner
    DEFAULT_TIMEOUT = 30

    def initialize(client: nil, model: ENV['LLM_MODEL_NAME'], timeout: DEFAULT_TIMEOUT, logger: Rails.logger)
      @client = client || (defined?(::LLM::OpenAIClient) ? ::LLM::OpenAIClient.instance : nil)
      @model = model.presence
      @timeout = timeout.to_i > 0 ? timeout.to_i : DEFAULT_TIMEOUT
      @logger = logger
    end

    def with_logging(payload, &block)
      ActiveSupport::Notifications.instrument("llm.call", payload.merge(model: @model)) { yield(it) }
    end

    # Returns an array of tool call events.
    # Each event is a Hash: { name:, arguments: Hash }
    def call(messages:, tools: [], procedure_id: nil, rule: nil, action: nil, user_id: nil)
      returned_value, raised_error = nil, nil

      with_logging(procedure_id:, rule:, action:, user_id:) do |payload|
        response = @client.chat({
          messages: messages,
          tools: tools,
          tool_choice: 'auto',
          temperature: 0,
          model: @model,
        })
        raw = response.respond_to?(:raw_response) ? response.raw_response : response
        msg = raw.dig('choices', 0, 'message') || {}
        raw_calls = msg['tool_calls'] || []

        payload[:prompt_tokens] = raw.dig('usage', 'prompt_tokens')
        payload[:completion_tokens] = raw.dig('usage', 'completion_tokens')
        payload[:status] = raw['status'] || 200

        returned_value = raw_calls.map do |tc|
          fn = tc['function'] || {}
          {
            name: fn['name'],
            arguments: parse_args(fn['arguments']),
            model: @model,
          }
        end
      rescue => e
        raised_error = e
        payload[:exception] = e
      end

      if raised_error
        raise raised_error
      else
        returned_value
      end
    end

    private

    def parse_args(str)
      return {} if str.blank?
      JSON.parse(str)
    rescue JSON::ParserError
      # Attempt to salvage simple key/value pairs; fallback to empty
      {}
    end
  end
end
