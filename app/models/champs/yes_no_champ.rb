class Champs::YesNoChamp < Champs::BooleanChamp
  def legend_label?
    true
  end

  def html_label?
    false
  end

  def yes_input_id
    "#{input_id}-yes"
  end

  def no_input_id
    "#{input_id}-no"
  end

  def focusable_input_id
    yes_input_id
  end
end
