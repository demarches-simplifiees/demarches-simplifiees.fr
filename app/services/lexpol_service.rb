# frozen_string_literal: true

class LexpolService
  FIXED_METADATA_INDIVIDUEL = [
    ["individual.nom", "Demandeur nom"],
    ["individual.prenom", "Demandeur prénom"],
    ["individual.gender", "Demandeur civilité"],
    ["mandataire_full_name", "Mandataire"],
    ["user.email", "Demandeur email"]
  ].freeze

  FIXED_METADATA_ENTREPRISE =
    [
      ["etablissement.entreprise_forme_juridique", "Entreprise forme juridique"],
      ["etablissement.entreprise_nom_commercial", "Entreprise nom commercial"],
      ["etablissement.entreprise_raison_sociale", "Entreprise raison sociale"],
      ["etablissement.siret", "Etablissement numéro TAHITI"],
      ["etablissement.adresse", "Etablissement adresse"]
    ].freeze
  # %w[entreprise_forme_juridique entreprise_nom_commercial entreprise_raison_sociale entreprise_numero_tahiti entreprise_adresse etablissement_code_postal etablissement_adresse etablissement_numero_tahiti].map { |v| [v, v] }.freeze

  FIXED_META_DATA = [
    ["depose_at", 'Dossier déposé le'],
    ["en_instruction_at", 'Dossier passé en instruction le'],
    ["processed_at", 'Dossier traité le'],
    ["followers_instructeurs.last.email", 'Dossier instruit par']
  ].freeze

  attr_reader :champ, :dossier, :apilexpol

  def initialize(champ:, dossier:, apilexpol:)
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
    nor = apilexpol.create_dossier(model_id, build_variables)
    return nil if nor.blank?

    champ.update!(value: nor)
    refresh_lexpol_data!
    nor
  end

  def update_dossier
    return nil if champ.value.blank?
    apilexpol.update_dossier(champ.value, build_variables)
    refresh_lexpol_data!
    champ.value
  end

  def build_variables
    variables = dossier.champs.root.reduce({}) do |variables, champ|
      variables[champ.libelle] = LexpolFieldsService.format_lexpol_value(champ) if champ.present?
      variables
    end
    LexpolService.default_mapping(champ.type_de_champ).reduce(variables) do |variables, (source_field, target_field)|
      raw_values = LexpolFieldsService.object_field_values(dossier, source_field)
      final_values = raw_values.map { |val| LexpolFieldsService.format_lexpol_value(val) }
      variables[target_field] = final_values.compact_blank.join(', ')
      variables
    end
  end

  def refresh_lexpol_data!
    return if champ.value.blank?
    dossier_info = apilexpol.get_dossier_infos(champ.value)
    champ.lexpol_status = dossier_info['statut_libelle']
    champ.lexpol_dossier_url = dossier_info['lienDossier']
    champ.save!
  end

  def model_id
    champ.type_de_champ.options&.[]('lexpol_modele')
  end

  def self.lexpol_variables(lexpol_type_de_champ)
    default_variables = default_mapping(lexpol_type_de_champ).values
    champ_variables = lexpol_type_de_champ.revision.types_de_champ.map(&:libelle)
    (default_variables + champ_variables).sort_by(&:downcase)
  end

  private

  def self.default_mapping(lexpol_type_de_champ)
    demandeur_mapping = lexpol_type_de_champ.procedure.for_individual? ? FIXED_METADATA_INDIVIDUEL : FIXED_METADATA_ENTREPRISE

    [*demandeur_mapping, *FIXED_META_DATA, *user_mapping(lexpol_type_de_champ)].to_h
  end

  def self.user_mapping(lexpol_type_de_champ)
    mapping_raw = lexpol_type_de_champ.lexpol_mapping || ""
    mapping_raw.lines.map(&:strip).compact_blank
      .map { |ligne| ligne.include?('=') ? ligne.split('=').map(&:strip) : [ligne, ligne] }
  end
end
