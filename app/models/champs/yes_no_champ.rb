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

  def self.options
    [[I18n.t('activerecord.attributes.type_de_champ.type_champs.yes_no_true'), true], [I18n.t('activerecord.attributes.type_de_champ.type_champs.yes_no_false'), false]]
  end
end
