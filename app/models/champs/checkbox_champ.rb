# frozen_string_literal: true

class Champs::CheckboxChamp < Champs::BooleanChamp
  def legend_label?
    false
  end

  def self.options
    [[I18n.t('activerecord.attributes.type_de_champ.type_champs.checkbox_true'), true], [I18n.t('activerecord.attributes.type_de_champ.type_champs.checkbox_false'), false]]
  end

  def html_label?
    false
  end

  def single_checkbox?
    true
  end
end
