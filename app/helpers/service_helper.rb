# frozen_string_literal: true

module ServiceHelper
  def formatted_horaires(horaires)
    horaires.gsub(/\S/, &:downcase)
  end
end
