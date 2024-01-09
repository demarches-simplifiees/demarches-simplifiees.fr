class Champs::CiviliteChamp < Champ
  validates :value, inclusion: ["M.", "Mme"], allow_nil: true, allow_blank: false

  def html_label?
    false
  end

  def female_input_id
    "#{input_id}-female"
  end

  def male_input_id
    "#{input_id}-male"
  end

  def focusable_input_id
    female_input_id
  end
end
