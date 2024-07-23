class ExportTemplate < ApplicationRecord
  include TagsSubstitutionConcern

  belongs_to :groupe_instructeur
  has_one :procedure, through: :groupe_instructeur
  has_many :exports, dependent: :nullify
  validates_with ExportTemplateValidator

  DOSSIER_STATE = Dossier.states.fetch(:en_construction)
  FORMAT_DATE = "%Y-%m-%d"

  def set_default_values_for_zip
    self.kind = 'zip'
    content["default_dossier_directory"] = tiptap_json("dossier-")
    content["pdf_name"] = tiptap_json("export_")

    content["pjs"] = []
    procedure.exportables_pieces_jointes.each do |pj|
      content["pjs"] << { "stable_id" => pj.stable_id.to_s, "path" => tiptap_json("#{pj.libelle.parameterize}-") }
    end
  end

  def zip?
    kind == 'zip'
  end

  def tabular?
    kind != 'zip'
  end

  def paths=(json_paths)
    content["columns"] = json_paths.compact_blank
      .map { JSON.parse(_1).symbolize_keys }
      .map { |p| p.tap { _1[:libelle] = libelle_for_path_hash(_1) } }
      .filter { _1[:libelle].present? }
  end

  def paths
    columns&.map(&:symbolize_keys)
  end

  def all_tdc_paths
    procedure.types_de_champ_for_procedure_presentation.not_repetition.map do |tdc|
      tdc.paths_for_export.map do
        _1.merge({ libelle: saved_libelle(_1) || _1[:libelle] })
      end
    end
  end

  def all_repetable_tdc_paths
    procedure
      .types_de_champ_for_procedure_presentation
      .repetition
      .filter_map do |type_de_champ_repetition|
        types_de_champ = procedure.types_de_champ_for_procedure_presentation(type_de_champ_repetition)

        if types_de_champ.present?
          h = {}
          h[:libelle] = type_de_champ_repetition.libelle
          h[:types_de_champ] = types_de_champ.map do |tdc|
            tdc.paths_for_export(repetition_champ_stable_id: type_de_champ_repetition.stable_id).map do
              _1.merge({ libelle: saved_libelle(_1) || _1[:libelle] })
            end
          end
          h
        end
      end
  end

  def all_usager_paths
    dossier_columns_to_path(all_usager_columns)
  end

  def all_dossier_paths
    dossier_columns_to_path(all_dossier_columns)
  end

  def columns
    content["columns"]
  end

  def tdc_columns
    columns.filter { _1['source'] == 'tdc' }
  end

  def columns_without_repet
    columns.filter { _1['source'] != 'repet' }
  end

  def repetable_columns
    columns.filter { _1['source'] == 'repet' }
      .group_by { _1['repetition_champ_stable_id'] }
  end

  def tiptap_default_dossier_directory=(body)
    self.content["default_dossier_directory"] = JSON.parse(body)
  end

  def tiptap_default_dossier_directory
    tiptap_content("default_dossier_directory")
  end

  def tiptap_pdf_name=(body)
    self.content["pdf_name"] = JSON.parse(body)
  end

  def tiptap_pdf_name
    tiptap_content("pdf_name")
  end

  def content_for_pj(pj)
    content_for_pj_id(pj.stable_id)&.to_json
  end

  def assign_pj_names(pj_params)
    self.content["pjs"] = []
    pj_params.each do |pj_param|
      self.content["pjs"] << { stable_id: pj_param[0].delete_prefix("tiptap_pj_"), path: JSON.parse(pj_param[1]) }
    end
  end

  def attachment_and_path(dossier, attachment, index: 0, row_index: nil, champ: nil)
    [
      attachment,
      path(dossier, attachment, index:, row_index:, champ:)
    ]
  end

  def tiptap_convert(dossier, param)
    if content[param]["content"]&.first&.[]("content")
      render_attributes_for(content[param], dossier)
    end
  end

  def tiptap_convert_pj(dossier, pj_stable_id, attachment = nil)
    if content_for_pj_id(pj_stable_id)["content"]&.first&.[]("content")
      render_attributes_for(content_for_pj_id(pj_stable_id), dossier, attachment)
    end
  end

  def render_attributes_for(content_for, dossier, attachment = nil)
    tiptap = TiptapService.new
    used_tags = tiptap.used_tags_and_libelle_for(content_for.deep_symbolize_keys)
    substitutions = tags_substitutions(used_tags, dossier, escape: false, memoize: true)
    substitutions['original-filename'] = attachment.filename.base if attachment
    tiptap.to_path(content_for.deep_symbolize_keys, substitutions)
  end

  def specific_tags
    tags_categorized.slice(:individual, :etablissement, :dossier).values.flatten
  end

  def tags_for_pj
    specific_tags.push({
      libelle: 'nom original du fichier',
      id: 'original-filename',
      maybe_null: false
    })
  end

  def columns_meta
    {
      id: { libelle: "ID", get_value: -> (d) { d.id.to_s } },
      email: { libelle: "Email", get_value: -> (d) { d.user_email_for(:display) } },
      france_connecte: { libelle: 'FranceConnect ?', get_value: -> (d) { d.user_from_france_connect? } },
      civilite: { libelle: "Civilité", get_value: -> (d) { d.individual&.gender } },
      last_name: { libelle: 'Nom', get_value: -> (d) { d.individual&.nom } },
      first_name: { libelle: 'Prénom', get_value: -> (d) { d.individual&.prenom } },
      for_tiers: { libelle: "Dépôt pour un tiers", get_value: -> (d) { d.for_tiers } },
      mandataire_last_name: { libelle: 'Nom du mandataire', get_value: -> (d) { d.mandataire_last_name } },
      mandataire_first_name: { libelle: 'Prénom du mandataire', get_value: -> (d) { d.mandataire_first_name } },
      date_de_naissance: { libelle: 'Date de naissance', get_value: -> (d) { d.individual&.birthdate } },
      etablissement_siret: { libelle: 'Établissement SIRET', get_value: -> (d) { d.etablissement&.siret } },
      etablissement_siege_social: { libelle: 'Établissement siège social', get_value: -> (d) { d.etablissement&.siege_social } },
      etablissement_naf: { libelle: 'Établissement NAF', get_value: -> (d) { d.etablissement&.naf } },
      etablissement_libelle_naf: { libelle: 'Établissement libellé NAF', get_value: -> (d) { d.etablissement&.libelle_naf } },
      etablissement_adresse: { libelle: 'Établissement Adresse', get_value: -> (d) { d.etablissement&.adresse } },
      etablissement_numero_voie: { libelle: 'Établissement numero voie', get_value: -> (d) { d.etablissement&.numero_voie } },
      etablissement_type_voie: { libelle: 'Établissement type voie', get_value: -> (d) { d.etablissement&.type_voie } },
      etablissement_nom_voie: { libelle: 'Établissement nom voie', get_value: -> (d) { d.etablissement&.nom_voie } },
      etablissement_complement_adresse: { libelle: 'Établissement complément adresse', get_value: -> (d) { d.etablissement&.complement_adresse } },
      etablissement_code_postal: { libelle: 'Établissement code postal', get_value: -> (d) { d.etablissement&.code_postal } },
      etablissement_localite: { libelle: 'Établissement localité', get_value: -> (d) { d.etablissement&.localite } },
      etablissement_code_insee_localite: { libelle: 'Établissement code INSEE localité', get_value: -> (_d) { etablissement&.code_insee_localite } },
      entreprise_siren: { libelle: 'Entreprise SIREN', get_value: -> (d) { d.etablissement&.entreprise_siren } },
      entreprise_capital_social: { libelle: 'Entreprise capital social', get_value: -> (d) { d.etablissement&.entreprise_capital_social } },
      entreprise_numero_tva_intracommunautaire: { libelle: 'Entreprise numero TVA intracommunautaire', get_value: -> (d) { d.etablissement&.entreprise_numero_tva_intracommunautaire } },
      entreprise_forme_juridique: { libelle: 'Entreprise forme juridique', get_value: -> (d) { d.etablissement&.entreprise_forme_juridique } },
      entreprise_forme_juridique_code: { libelle: 'Entreprise forme juridique code', get_value: -> (d) { d.etablissement&.entreprise_forme_juridique_code } },
      entreprise_nom_commercial: { libelle: 'Entreprise nom commercial', get_value: -> (d) { d.etablissement&.entreprise_nom_commercial } },
      entreprise_raison_sociale: { libelle: 'Entreprise raison sociale', get_value: -> (d) { d.etablissement&.entreprise_raison_sociale } },
      entreprise_siret_siege_social: { libelle: 'Entreprise SIRET siège social', get_value: -> (d) { d.etablissement&.entreprise_siret_siege_social } },
      entreprise_code_effectif_entreprise: { libelle: 'Entreprise code effectif entreprise', get_value: -> (d) { d.etablissement&.entreprise_code_effectif_entreprise } },
      entreprise_date_creation: { libelle: 'Entreprise date de création', get_value: -> (d) { d.etablissement&.entreprise_date_creation } },
      entreprise_etat_administratif: { libelle: 'Entreprise état administratif', get_value: -> (d) { d.etablissement&.entreprise_etat_administratif } },
      entreprise_nom: { libelle: 'Entreprise nom', get_value: -> (d) { d.etablissement&.entreprise_nom } },
      entreprise_prenom: { libelle: 'Entreprise prénom', get_value: -> (d) { d.etablissement&.entreprise_prenom } },
      association_rna: { libelle: 'Association RNA', get_value: -> (d) { d.etablissement&.association_rna } },
      association_titre: { libelle: 'Association titre', get_value: -> (d) { d.etablissement&.association_titre } },
      association_objet: { libelle: 'Association objet', get_value: -> (d) { d.etablissement&.association_objet } },
      association_date_creation: { libelle: 'Association date de création', get_value: -> (d) { d.etablissement&.association_date_creation } },
      association_date_declaration: { libelle: 'Association date de déclaration', get_value: -> (d) { d.etablissement&.association_date_declaration } },
      association_date_publication: { libelle: 'Association date de publication', get_value: -> (d) { d.etablissement&.association_date_publication } },
      domaine_fonctionnel: { libelle: 'Domaine Fonctionnel', get_value: -> (d) { d.procedure.chorus_configuration.domaine_fonctionnel&.fetch("code") { '' } } },
      referentiel_prog: { libelle: 'Référentiel De Programmation', get_value: -> (d) { d.procedure.chorus_configuration.referentiel_de_programmation&.fetch("code") { '' } } },
      centre_de_cout: { libelle: 'Centre De Coût', get_value: -> (d) { d.procedure.chorus_configuration.centre_de_cout&.fetch("code") { '' } } },
      archived: { libelle: 'Archivé', get_value: -> (d) { d.archived } },
      dossier_state: { libelle: 'État du dossier', get_value: -> (d) { Dossier.human_attribute_name("state.#{d.state}") } },
      updated_at: { libelle: 'Dernière mise à jour le', get_value: -> (d) { d.updated_at } },
      last_champ_updated_at: { libelle: 'Dernière mise à jour du dossier le', get_value: -> (d) { d.last_champ_updated_at } },
      depose_at: { libelle: 'Déposé le', get_value: -> (d) { d.depose_at } },
      en_instruction_at: { libelle: 'Passé en instruction le', get_value: -> (d) { d.en_instruction_at } },
      sva_svr_decision_on: { libelle: "Date décision #{procedure.sva_svr_configuration.human_decision}", get_value: -> (d) { d.sva_svr_decision_on } },
      processed_at: { libelle: 'Traité le', get_value: -> (d) { d.processed_at } },
      motivation: { libelle: 'Motivation de la décision', get_value: -> (d) { d.motivation } },
      instructeurs: { libelle: 'Instructeurs', get_value: -> (d) { d.followers_instructeurs.map(&:email).join(' ') } },
      groupe_instructeur: { libelle: 'Groupe instructeur', get_value: -> (d) { d.groupe_instructeur.label } }
    }
  end

  private

  def libelle_for_path_hash(current_column)
    case current_column[:source]
    when 'tdc', 'repet'
      active_type_de_champ = procedure.active_revision.types_de_champ.find_by(stable_id: current_column[:stable_id])
      if active_type_de_champ
        active_libelle = active_type_de_champ.libelle_for_path(current_column[:path])
        saved_libelle(current_column) || active_libelle
      end
    when 'dossier'
      columns_meta[current_column[:path].to_sym][:libelle]
    end
  end

  def saved_libelle(path_h)
    paths&.find { _1.slice(:path, :stable_id) == path_h.slice(:path, :stable_id) }&.dig(:libelle)
  end

  def dossier_columns_to_path(columns)
    columns.map { { path: _1.to_s, source: 'dossier', libelle: columns_meta[_1][:libelle] } }
  end

  def tiptap_content(key)
    content[key]&.to_json
  end

  def tiptap_json(prefix)
    {
      "type" => "doc",
      "content" => [
        { "type" => "paragraph", "content" => [{ "text" => prefix, "type" => "text" }, { "type" => "mention", "attrs" => DOSSIER_ID_TAG.stringify_keys }] }
      ]
    }
  end

  def content_for_pj_id(stable_id)
    content_for_stable_id = content["pjs"].find { _1.symbolize_keys[:stable_id] == stable_id.to_s }
    content_for_stable_id.symbolize_keys.fetch(:path)
  end

  def folder(dossier)
    render_attributes_for(content["default_dossier_directory"], dossier)
  end

  def export_path(dossier)
    File.join(folder(dossier), export_filename(dossier))
  end

  def export_filename(dossier)
    "#{render_attributes_for(content["pdf_name"], dossier)}.pdf"
  end

  def path(dossier, attachment, index: 0, row_index: nil, champ: nil)
    if attachment.name == 'pdf_export_for_instructeur'
      return export_path(dossier)
    end

    dir_path = case attachment.record_type
    when 'Dossier'
      'dossier'
    when 'Commentaire'
      'messagerie'
    when 'Avis'
      'avis'
    when 'Attestation', 'Etablissement'
      'pieces_justificatives'
    else
      # for attachment
      return attachment_path(dossier, attachment, index, row_index, champ)
    end

    File.join(folder(dossier), dir_path, attachment.filename.to_s)
  end

  def attachment_path(dossier, attachment, index, row_index, champ)
    stable_id = champ.stable_id
    tiptap_pj = content["pjs"].find { |pj| pj["stable_id"] == stable_id.to_s }
    if tiptap_pj
      File.join(folder(dossier), tiptap_convert_pj(dossier, stable_id, attachment) + suffix(attachment, index, row_index))
    else
      File.join(folder(dossier), "erreur_renommage", attachment.filename.to_s)
    end
  end

  def suffix(attachment, index, row_index)
    suffix = "-#{index + 1}"
    suffix += "-#{row_index + 1}" if row_index.present?

    suffix + attachment.filename.extension_with_delimiter
  end

  def all_usager_columns
    columns = []
    columns.push :id, :email, :france_connecte
    if procedure.for_individual?
      columns.push :civilite, :last_name, :first_name, :for_tiers, :mandataire_last_name, :mandataire_first_name
      if procedure.ask_birthday
        columns.push :date_de_naissance
      end
    else
      columns.push(
        :etablissement_siret, :etablissement_siege_social, :etablissement_naf, :etablissement_libelle_naf,
        :etablissement_adresse, :etablissement_numero_voie, :etablissement_type_voie, :etablissement_nom_voie, :etablissement_complement_adresse, :etablissement_code_postal, :etablissement_localite, :etablissement_code_insee_localite,
        :entreprise_siren, :entreprise_capital_social, :entreprise_numero_tva_intracommunautaire,
        :entreprise_forme_juridique, :entreprise_forme_juridique_code,
        :entreprise_nom_commercial, :entreprise_raison_sociale,
        :entreprise_siret_siege_social,
        :entreprise_code_effectif_entreprise
      )
    end

    if procedure.chorusable? && procedure.chorus_configuration.complete?
      columns.push(:domaine_fonctionnel, :referentiel_prog, :centre_de_cout)
    end

    columns
  end

  def all_dossier_columns
    columns = []
    columns.push(
      :archived, :dossier_state, :updated_at, :last_champ_updated_at,
      :depose_at, :en_instruction_at,
      procedure.sva_svr_enabled? ? :sva_svr_decision_on : nil,
      :processed_at,
      :motivation,
      :instructeurs,
      procedure.routing_enabled? ? :groupe_instructeur : nil
    ).compact
  end
end
