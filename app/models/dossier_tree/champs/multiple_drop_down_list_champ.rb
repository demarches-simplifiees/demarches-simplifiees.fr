# frozen_string_literal: true

class DossierTree::Champs::MultipleDropDownListChamp < DossierTree::Champ
  def to_s
    return "" if blank?
    value.join(", ")
  end
end
