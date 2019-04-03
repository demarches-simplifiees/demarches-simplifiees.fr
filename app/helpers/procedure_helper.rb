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
      isAnnotation: false,
      typeDeChampsTypes: types_de_champ_types,
      typeDeChamps: types_de_champ_as_json(procedure.types_de_champ),
      baseUrl: procedure_types_de_champ_path(procedure),
      directUploadUrl: rails_direct_uploads_url
    }
  end

  def types_de_champ_private_data(procedure)
    {
      isAnnotation: true,
      typeDeChampsTypes: types_de_champ_types,
      typeDeChamps: types_de_champ_as_json(procedure.types_de_champ_private),
      baseUrl: procedure_types_de_champ_path(procedure),
      directUploadUrl: rails_direct_uploads_url
    }
  end

  private

  TOGGLES = {
    TypeDeChamp.type_champs.fetch(:integer_number)  => :champ_integer_number?,
    TypeDeChamp.type_champs.fetch(:repetition)      => :champ_repetition?
  }

  def types_de_champ_types
    types_de_champ_types = TypeDeChamp.type_de_champs_list_fr

    types_de_champ_types.select! do |tdc|
      toggle = TOGGLES[tdc.last]
      toggle.blank? || Flipflop.send(toggle)
    end

    types_de_champ_types
  end

  TYPES_DE_CHAMP_BASE = {
    except: [
      :created_at,
      :options,
      :order_place,
      :parent_id,
      :private,
      :procedure_id,
      :stable_id,
      :type,
      :updated_at
    ],
    methods: [
      :cadastres,
      :drop_down_list_value,
      :parcelles_agricoles,
      :piece_justificative_template_filename,
      :piece_justificative_template_url,
      :quartiers_prioritaires
    ]
  }
  TYPES_DE_CHAMP = TYPES_DE_CHAMP_BASE
    .merge(include: { types_de_champ: TYPES_DE_CHAMP_BASE })

  def types_de_champ_as_json(types_de_champ)
    types_de_champ.includes(:drop_down_list,
      piece_justificative_template_attachment: :blob,
      types_de_champ: [:drop_down_list, piece_justificative_template_attachment: :blob])
      .as_json(TYPES_DE_CHAMP)
  end
end
