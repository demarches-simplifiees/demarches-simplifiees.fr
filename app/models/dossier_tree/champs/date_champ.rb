# frozen_string_literal: true

class DossierTree::Champs::DateChamp < DossierTree::Champ
  def to_s
    return "" if blank?
    I18n.l(value, format: '%d %B %Y')
  end
end
