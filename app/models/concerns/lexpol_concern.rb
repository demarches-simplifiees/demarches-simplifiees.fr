module LexpolConcern
  extend ActiveSupport::Concern

  def lexpol_create_dossier
    lexpol_service = APILexpol.new
    nor = lexpol_service.create_dossier(598706)
    update(value: nor)
    refresh_lexpol_data!
    true
  rescue => e
    flash[:error] = "Erreur lors de la création du dossier : #{e.message}"
    redirect_to request.referer || root_path
    false
  end

  def lexpol_update_dossier(variables)
    return false if value.blank?

    lexpol_service = APILexpol.new
    begin
      lexpol_service.update_dossier(value, variables)
      refresh_lexpol_data!
      true
    rescue => e
      errors.add(:base, e.message)
      false
    end
  end

  def refresh_lexpol_data!
    return if value.blank?

    lexpol_service = APILexpol.new
    status_info = lexpol_service.get_dossier_status(value)
    dossier_info = lexpol_service.get_dossier_infos(value)

    self.lexpol_status = status_info['libelle']
    self.lexpol_dossier_url = dossier_info['lienDossier']
    save!
  rescue => e
    errors.add(:base, "Impossible de rafraîchir les données Lexpol : #{e.message}")
  end
end
