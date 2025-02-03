# frozen_string_literal: true

require 'langchain'

# Albert uses OpenAI interface.

module LLM
  class OpenAIClient
    def self.instance
      Langchain::LLM::OpenAI.new(
        api_key: ENV["LLM_API_KEY"],
        llm_options: {
          uri_base: ENV.fetch("LLM_URI_BASE")
        },
        default_options: {
          temperature: 0.0,
          chat_model: ENV.fetch("LLM_MODEL_NAME")
        }
      )
    end
  end
end
