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
    parts = procedure.brouillon? ? [content_tag(:span, 'démarche en test', class: 'badge')] : []
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

  def types_de_champ_data(procedure)
    {
      type: "champ",
      types_de_champ_options: types_de_champ_options.to_json,
      types_de_champ: types_de_champ_as_json(procedure.types_de_champ).to_json,
      direct_uploads_url: rails_direct_uploads_url,
      drag_icon_url: image_url("icons/drag.svg")
    }
  end

  def types_de_champ_private_data(procedure)
    {
      type: "annotation",
      types_de_champ_options: types_de_champ_options.to_json,
      types_de_champ: types_de_champ_as_json(procedure.types_de_champ_private).to_json,
      direct_uploads_url: rails_direct_uploads_url,
      drag_icon_url: image_url("icons/drag.svg")
    }
  end

  def procedure_data(procedure)
    {
      types_de_champ: types_de_champ_as_json(procedure.types_de_champ),
      types_de_champ_private: types_de_champ_as_json(procedure.types_de_champ_private)
    }.to_json
  end

  private

  TOGGLES = {
    TypeDeChamp.type_champs.fetch(:siret)           => :champ_siret?,
    TypeDeChamp.type_champs.fetch(:integer_number)  => :champ_integer_number?,
    TypeDeChamp.type_champs.fetch(:repetition)      => :champ_repetition?
  }

  def types_de_champ_options
    types_de_champ = TypeDeChamp.type_de_champs_list_fr

    types_de_champ.select! do |tdc|
      toggle = TOGGLES[tdc.last]
      toggle.blank? || Flipflop.send(toggle)
    end

    types_de_champ
  end

  def types_de_champ_as_json(types_de_champ)
    types_de_champ.as_json(except: [:created_at, :updated_at],
      methods: [:piece_justificative_template_filename, :piece_justificative_template_url],
      include: { drop_down_list: { only: :value } })
  end
end
