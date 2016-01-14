class ProcedureDecorator < Draper::Decorator
  delegate_all

  def lien
    h.new_users_dossiers_url(procedure_id: id)
  end

  def logo_img
    return 'logo-tps.png' if logo.blank?
    logo
  end
  def geographic_information
    module_api_carto
  end
end
