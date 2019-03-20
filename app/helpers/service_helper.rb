module ServiceHelper
  def formatted_horaires(horaires)
    horaires.sub(/\S/, &:downcase)
  end
end
