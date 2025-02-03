# frozen_string_literal: true

require 'langchain'

# Albert uses OpenAI interface.

module LLM
  class OpenAIClient
    def self.instance
      Langchain::LLM::OpenAI.new(
        api_key: ENV["LLM_API_KEY"],
        llm_options: {
          uri_base: ENV.fetch("LLM_URI_BASE"),
        },
        default_options: {
          temperature: ENV.fetch("LLM_TEMPERATURE", 0.2).to_f,
          chat_model: ENV.fetch("LLM_MODEL_NAME"),
        }
      )
    end
  end
end
