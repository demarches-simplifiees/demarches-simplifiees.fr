# frozen_string_literal: true

class Champs::CiviliteChamp < Champ
  validates :value, inclusion: ["M.", "Mme"], allow_nil: true, allow_blank: false, if: :validate_champ_value?

  def legend_label?
    true
  end

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

  def female?
    value == Individual::GENDER_FEMALE
  end

  def male?
    value == Individual::GENDER_MALE
  end

  def value=(value)
    case value
    when '0', Individual::GENDER_FEMALE
      super(Individual::GENDER_FEMALE)
    when '1', Individual::GENDER_MALE
      super(Individual::GENDER_MALE)
    else
      super(value)
    end
  end
end
