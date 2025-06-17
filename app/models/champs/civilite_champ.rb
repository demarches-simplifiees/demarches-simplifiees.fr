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

  def female_input_label_id
    "#{female_input_id}-label"
  end

  def male_input_id
    "#{input_id}-male"
  end

  def male_input_label_id
    "#{male_input_id}-label"
  end

  def focusable_input_id
    female_input_id
  end
end
