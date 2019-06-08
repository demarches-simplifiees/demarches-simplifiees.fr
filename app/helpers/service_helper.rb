module ServiceHelper
  def formatted_horaires(horaires)
    horaires.gsub(/\S/, &:downcase)
  end
end
