class ProcedureDecorator < Draper::Decorator

  delegate_all

  def lien
    h.commencer_url(procedure_path: path) unless path.nil?
  end

  def created_at_fr
    created_at.localtime.strftime('%d/%m/%Y %H:%M')
  end

  def logo_img
    return h.image_url(LOGO_NAME) if logo.blank?
    File.join(STORAGE_URL, File.basename(logo.path))
  end
  def geographic_information
    module_api_carto
  end
end
