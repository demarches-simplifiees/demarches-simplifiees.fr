# frozen_string_literal: true

module ServiceHelper
  def formatted_horaires(horaires)
    horaires.sub(/\S/, &:downcase)
  end
end
