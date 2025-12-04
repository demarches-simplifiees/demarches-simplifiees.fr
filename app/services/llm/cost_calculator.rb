# frozen_string_literal: true

module LLM
  class CostCalculator
    PRICING = {
      'mistralai/mistral-medium-3.1' => {
        prompt: 0.0027 / 1000, # $0.0027 per 1K tokens (OpenRouter)
        completion: 0.0081 / 1000, # $0.0081 per 1K tokens
      },
      # Add other models
    }

    def self.calculate(model:, prompt_tokens:, completion_tokens:)
      rates = PRICING[model] || { prompt: 0, completion: 0 }
      (prompt_tokens * rates[:prompt]) + (completion_tokens * rates[:completion])
    end
  end
end
