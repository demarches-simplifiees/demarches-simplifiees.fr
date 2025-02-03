# frozen_string_literal: true

require 'langchain'

module LLM
  class SonnetClient
    def self.instance
      Langchain::LLM::Anthropic.new(
        api_key: ENV["LLM_API_KEY"],
        llm_options: {},
       default_options: {
         temperature: 0.0,
         chat_model: "claude-3-5-sonnet-20241022"
       }
      )
    end
  end
end
