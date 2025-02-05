class LexpolService
  FIXED_METADATA_INDIVIDUEL = [
    "demandeur_nom",
    "demandeur_prenom",
    "demandeur_civilite",
    "demandeur_email"
  ].freeze

  FIXED_METADATA_ENTREPRISE = [
    "entreprise_forme_juridique",
    "entreprise_nom_commercial",
    "entreprise_raison_sociale",
    "entreprise_numero_tahiti",
    "entreprise_adresse",
    "etablissement_code_postal",
    "etablissement_adresse",
    "etablissement_numero_tahiti"
  ].freeze

  attr_reader :champ, :dossier, :apilexpol

  def initialize(champ:, dossier:, apilexpol: APILexpol.new)
    @champ = champ
    @dossier = dossier
    @apilexpol = apilexpol
  end

  def upsert_dossier(force_create: false)
    if force_create || champ.value.blank?
      create_dossier
    else
      update_dossier
    end
  end

  def create_dossier
    variables = build_variables
    nor = apilexpol.create_dossier(model_id, variables)
    return nil if nor.blank?

    champ.update!(value: nor)
    refresh_lexpol_data!
    nor
  rescue => e
    Rails.logger.error("Erreur Lexpol create_dossier : #{e.message}")
    nil
  end

  def update_dossier
    return nil if champ.value.blank?
    variables = build_variables
    apilexpol.update_dossier(champ.value, variables)
    refresh_lexpol_data!
    champ.value
  rescue => e
    Rails.logger.error("Erreur Lexpol update_dossier : #{e.message}")
    nil
  end

  def build_variables
    champs = (dossier.champs_public + dossier.champs_private)
    dynamic_mapping = champs.map(&:libelle).uniq.map { |libelle| "#{libelle}=#{libelle}" }.join("\n")

    fixed_metadata = dossier.for_individual? ? FIXED_METADATA_INDIVIDUEL : FIXED_METADATA_ENTREPRISE
    fixed_mapping = fixed_metadata.map { |m| "#{m}=#{m}" }.join("\n")

    admin_mapping = champ.type_de_champ.lexpol_mapping || ""

    mapping_raw = [dynamic_mapping, fixed_mapping, admin_mapping].join("\n")

    mapping = mapping_raw.lines.map(&:strip).compact_blank
      .map { |ligne| ligne.include?('=') ? ligne.split('=').map(&:strip) : [ligne, ligne] }
      .to_h

    mapping.reduce({}) do |variables, (source_field, target_field)|
      raw_values = LexpolFieldsService.object_field_values(dossier, source_field)
      final_values = raw_values.map { |val| LexpolFieldsService.format_lexpol_value(val) }
      variables[target_field] = final_values.compact_blank.join(', ')
      variables
    end
  end

  def refresh_lexpol_data!
    return if champ.value.blank?
    status_info = apilexpol.get_dossier_status(champ.value)
    dossier_info = apilexpol.get_dossier_infos(champ.value)
    champ.lexpol_status = status_info[:libelle]
    champ.lexpol_dossier_url = dossier_info['lienDossier']
    champ.save!
  end

  def model_id
    champ.type_de_champ.options&.[]('lexpol_modele')
  end

  def self.available_variables_html(dynamic_fields, dossier)
    dynamic_variables = dynamic_fields.map(&:libelle).uniq.sort

    fixed_metadata = if dossier && dossier.for_individual?
      FIXED_METADATA_INDIVIDUEL
    else
      FIXED_METADATA_ENTREPRISE
    end

    html = "<div class='lexpol-available-vars'>"
    html << "<strong>Données du formulaire :</strong>"
    html << "<ul>" + dynamic_variables.map { |v| "<li>#{v}</li>" }.join + "</ul>"
    html << "<strong>Méta données :</strong>"
    html << "<ul>" + fixed_metadata.map { |v| "<li>#{v}</li>" }.join + "</ul>"
    html << "</div>"
  end
end
