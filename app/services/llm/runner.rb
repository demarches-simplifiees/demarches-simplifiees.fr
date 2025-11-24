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

    # Returns an array of tool call events.
    # Each event is a Hash: { name:, arguments: Hash }
    def call(messages:, tools: [], procedure_id: nil, rule: nil, action: nil, user_id: nil)
      ActiveSupport::Notifications.instrument("llm.call",
        procedure_id:,
        rule:,
        action:,
        user_id:,
        messages_count: messages.size) do |payload|
        params = {
          messages: messages,
          tools: tools,
          tool_choice: 'auto',
          temperature: 0,
        }
        params[:model] = @model if @model

        response = @client.chat(params)
        raw = response.respond_to?(:raw_response) ? response.raw_response : response
        msg = raw.dig('choices', 0, 'message') || {}
        raw_calls = msg['tool_calls'] || []

        # Enrichir le payload avec les détails de la réponse
        payload[:model] = @model
        payload[:prompt_tokens] = raw.dig('usage', 'prompt_tokens')
        payload[:completion_tokens] = raw.dig('usage', 'completion_tokens')
        payload[:status] = raw['status'] || 200

        raw_calls.map do |tc|
          fn = tc['function'] || {}
          {
            name: fn['name'],
            arguments: parse_args(fn['arguments']),
            model: @model,
          }
        end
      end
    rescue => e
      # Enrichir le payload avec l'erreur
      ActiveSupport::Notifications.instrument("llm.call",
        procedure_id:,
        rule:,
        action:,
        user_id:,
        messages_count: messages.size,
        exception: e) do |payload|
        payload[:error_class] = e.class.name
        payload[:error_message] = e.message
      end
      @logger.warn("[LLM::Runner] request failed: #{e.class}: #{e.message}")
      []
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
