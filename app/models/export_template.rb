# frozen_string_literal: true

class ExportTemplate < ApplicationRecord
  include TagsSubstitutionConcern

  belongs_to :groupe_instructeur
  has_one :procedure, through: :groupe_instructeur
  has_many :exports, dependent: :nullify

  enum kind: { zip: 'zip', csv: 'csv', xlsx: 'xlsx', ods: 'ods' }, _prefix: :template

  attribute :dossier_folder, :export_item
  attribute :export_pdf, :export_item
  attribute :pjs, :export_item, array: true

  before_validation :ensure_pjs_are_legit

  validates_with ExportTemplateValidator

  DOSSIER_STATE = Dossier.states.fetch(:en_construction)

  # when a pj has been added to a revision, it will not be present in the previous pjs
  # a default value is provided.
  def pj(tdc)
    pjs.find { _1.stable_id == tdc.stable_id } || ExportItem.default_pj(tdc)
  end

  def self.default(name: nil, kind: 'zip', groupe_instructeur:)
    # TODO: remove default values for tabular export
    dossier_folder = ExportItem.default(prefix: 'dossier')
    export_pdf = ExportItem.default(prefix: 'export')
    pjs = groupe_instructeur.procedure.exportables_pieces_jointes.map { |tdc| ExportItem.default_pj(tdc) }

    new(name:, kind:, groupe_instructeur:, dossier_folder:, export_pdf:, pjs:)
  end

  def tabular?
    kind != 'zip'
  end

  def tags
    tags_categorized.slice(:individual, :etablissement, :dossier).values.flatten
  end

  def pj_tags
    tags.push(
      libelle: 'nom original du fichier',
      id: 'original-filename'
    )
  end

  def attachment_path(dossier, attachment, index: 0, row_index: nil, champ: nil)
    file_path = if attachment.name == 'pdf_export_for_instructeur'
      export_pdf.path(dossier, attachment:)
    elsif attachment.record_type == 'Champ' && pj(champ.type_de_champ).enabled?
      pj(champ.type_de_champ).path(dossier, attachment:, index:, row_index:)
    else
      nil
    end

    File.join(dossier_folder.path(dossier), file_path) if file_path.present?
  end

  def columns=(columns)
    content["columns"] = columns.compact_blank
      .each { _1[:libelle] = libelle_for_column_hash(_1) }
      .filter { _1[:libelle].present? }
  end

  def columns
    content["columns"]&.map(&:symbolize_keys)
  end

def all_tdc_columns
    procedure.types_de_champ_for_procedure_presentation.not_repetition.map do |tdc|
      tdc.columns_for_export.map do
        _1.merge({ libelle: saved_libelle(_1) || _1[:libelle] })
      end
    end
  end

  def repetable_columns
    columns.filter { _1[:source] == 'repet' }
      .group_by { _1[:repetition_champ_stable_id] }
  end

  def all_repetable_tdc_columns
    procedure
      .types_de_champ_for_procedure_presentation
      .repetition
      .filter_map do |type_de_champ_repetition|
        types_de_champ = procedure.types_de_champ_for_procedure_presentation(type_de_champ_repetition)

        if types_de_champ.present?
          h = {}
          h[:libelle] = type_de_champ_repetition.libelle
          h[:types_de_champ] = types_de_champ.map do |tdc|
            tdc.columns_for_export(repetition_champ_stable_id: type_de_champ_repetition.stable_id).map do
              _1.merge({ libelle: saved_libelle(_1) || _1[:libelle] })
            end
          end
          h
        end
      end
  end

  def all_usager_columns
    dossier_columns_for(all_usager_column_keys)
  end

  def all_dossier_columns
    dossier_columns_for(all_dossier_column_keys)
  end

  private

  def ensure_pjs_are_legit
    legitimate_pj_stable_ids = procedure.exportables_pieces_jointes_for_all_versions.map(&:stable_id)

    self.pjs = pjs.filter { _1.stable_id.in?(legitimate_pj_stable_ids) }
  end

  def libelle_for_column_hash(current_column)
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
    columns&.find { _1.slice(:path, :stable_id) == path_h.slice(:path, :stable_id) }&.dig(:libelle)
  end

  def dossier_columns_for(columns)
    columns.map { { path: _1.to_s, source: 'dossier', libelle: columns_meta[_1][:libelle] } }
  end

  def all_usager_column_keys
    column_keys = []
    column_keys.push :id, :email, :france_connecte
    if procedure.for_individual?
      column_keys.push :civilite, :last_name, :first_name, :for_tiers, :mandataire_last_name, :mandataire_first_name
    else
      column_keys.push(
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
      column_keys.push(:domaine_fonctionnel, :referentiel_prog, :centre_de_cout)
    end

    column_keys
  end

  def all_dossier_column_keys
    column_keys = []
    column_keys.push(
      :archived, :dossier_state, :updated_at, :last_champ_updated_at,
      :depose_at, :en_instruction_at,
      procedure.sva_svr_enabled? ? :sva_svr_decision_on : nil,
      :processed_at,
      :motivation,
      :instructeurs,
      procedure.routing_enabled? ? :groupe_instructeur : nil
    ).compact
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
end
