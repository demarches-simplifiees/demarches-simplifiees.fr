# frozen_string_literal: true

class DossierTree::Champs::DatetimeChamp < DossierTree::Champ
  def to_s
    return "" if blank?
    I18n.l(value)
  end
end
