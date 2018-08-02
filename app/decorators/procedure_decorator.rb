class ProcedureDecorator < Draper::Decorator
  delegate_all

  def lien
    if path.present?
      if en_test?
        h.commencer_test_url(procedure_path: path)
      else
        h.commencer_url(procedure_path: path)
      end
    end
  end

  def created_at_fr
    created_at.localtime.strftime('%d/%m/%Y %H:%M')
  end

  def published_at_fr
    if published_at.present?
      published_at.localtime.strftime('%d/%m/%Y %H:%M')
    end
  end

  def logo_img
    if logo.blank?
      h.image_url(LOGO_NAME)
    else
      if Flipflop.remote_storage?
        (RemoteDownloader.new logo.filename).url
      else
        (LocalDownloader.new logo.path, 'logo').url
      end
    end
  end

  def geographic_information
    module_api_carto
  end
end
