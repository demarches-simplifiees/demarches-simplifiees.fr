# frozen_string_literal: true

class DossierTree::Champs::CheckboxChamp < DossierTree::Champ
  def to_s
    value ? "Oui" : "Non"
  end
end
