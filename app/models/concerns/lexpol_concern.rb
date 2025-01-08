module LexpolConcern
  extend ActiveSupport::Concern

  def lexpol_service
    @lexpol_service ||= APILexpol.new
  end

  def lexpol_create_dossier
    model_id = type_de_champ.lexpol_modele.presence
    nor = lexpol_service.create_dossier(model_id)
    update(value: nor)
    refresh_lexpol_data!
    true
  rescue => e
    flash[:error] = "Erreur lors de la création du dossier : #{e.message}"
    redirect_to(request.referer || root_path)
    false
  end

  def lexpol_update_dossier(variables)
    return false if value.blank?

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

    status_info  = lexpol_service.get_dossier_status(value)
    dossier_info = lexpol_service.get_dossier_infos(value)

    self.lexpol_status       = status_info['libelle']
    self.lexpol_dossier_url  = dossier_info['lienDossier']
    save!
  rescue => e
    errors.add(:base, "Impossible de rafraîchir les données Lexpol : #{e.message}")
  end
end
