# frozen_string_literal: true

module LLM
  class BaseImprover
    attr_reader :runner, :logger

    def initialize(runner: nil, logger: Rails.logger)
      @runner = runner
      @logger = logger
    end

    def run_tool_call(tool_definition:, messages:)
      return [] unless runner

      runner.call(messages:, tools: [tool_definition]) || []
    rescue => e
      logger.warn("[#{self.class.name}] tool call failed: #{e.class}: #{e.message}")
      []
    end

    def normalize_tool_calls(calls, tool_name)
      calls
        .filter { |call| call[:name] == tool_name }
        .map do |call|
          args = call[:arguments] || {}
          yield(args)
        end
        .compact
    end

    def generate_for(revision)
      messages = build_messages(revision)
      calls = run_tool_call(tool_definition: self.class::TOOL_DEFINITION, messages:)
      normalize_tool_calls(calls, self.class::TOOL_NAME) { |args| build_item(args) }
    end

    def build_messages(revision)
      schema = revision.schema_to_llm
      [
        { role: 'system', content: system_prompt },
        { role: 'user', content: format(schema_prompt, schema: JSON.dump(schema)) },
        { role: 'user', content: rules_prompt }
      ]
    end
  end
end
