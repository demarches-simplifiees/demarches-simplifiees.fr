# frozen_string_literal: true

class DossierTree::Champs::YesNoChamp < DossierTree::Champ
  def to_s
    return "" if blank?
    value ? "Oui" : "Non"
  end
end
