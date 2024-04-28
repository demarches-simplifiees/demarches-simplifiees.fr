# frozen_string_literal: true

module TableauDeBordHelper
  def tableau_de_bord_helper_path
    if current_administrateur.present?
      admin_procedures_path
    elsif current_instructeur.present?
      instructeur_procedures_path
    else
      dossiers_path
    end
  end
end
