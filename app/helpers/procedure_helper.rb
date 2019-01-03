module ProcedureHelper
  def procedure_lien(procedure)
    if procedure.path.present?
      if procedure.brouillon_avec_lien?
        commencer_test_url(path: procedure.path)
      else
        commencer_url(path: procedure.path)
      end
    end
  end

  def procedure_libelle(procedure)
    parts = procedure.brouillon? ? [content_tag(:span, 'démarche non publiée', class: 'badge')] : []
    parts << procedure.libelle
    safe_join(parts, ' ')
  end

  def procedure_modal_text(procedure, key)
    action = procedure.archivee? ? :reopen : :publish
    t(action, scope: [:modal, :publish, key])
  end

  def logo_img(procedure)
    logo = procedure.logo

    if logo.blank?
      ActionController::Base.helpers.image_url("marianne.svg")
    else
      if Flipflop.remote_storage?
        RemoteDownloader.new(logo.filename).url
      else
        LocalDownloader.new(logo.path, 'logo').url
      end
    end
  end
end
