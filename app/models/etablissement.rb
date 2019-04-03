class Etablissement < ApplicationRecord
  belongs_to :dossier

  has_one :champ, class_name: 'Champs::SiretChamp'
  has_many :exercices, dependent: :destroy

  accepts_nested_attributes_for :exercices

  validates :siret, presence: true
  validates :dossier_id, uniqueness: { allow_nil: true }

  def search_terms
    [
      entreprise_siren,
      entreprise_numero_tva_intracommunautaire,
      entreprise_forme_juridique,
      entreprise_forme_juridique_code,
      entreprise_nom_commercial,
      entreprise_raison_sociale,
      entreprise_siret_siege_social,
      entreprise_nom,
      entreprise_prenom,
      association_rna,
      association_titre,
      association_objet,
      siret,
      naf,
      libelle_naf,
      adresse,
      code_postal,
      localite,
      code_insee_localite
    ]
  end

  def spreadsheet_columns
    [
      ['Dossier ID', :dossier_id_for_export],
      ['Champ', :libelle_for_export],
      ['Établissement SIRET', :siret],
      ['Établissement siège social', :siege_social],
      ['Établissement NAF', :naf],
      ['Établissement libellé NAF', :libelle_naf],
      ['Établissement Adresse', :adresse],
      ['Établissement numero voie', :numero_voie],
      ['Établissement type voie', :type_voie],
      ['Établissement nom voie', :nom_voie],
      ['Établissement complément adresse', :complement_adresse],
      ['Établissement code postal', :code_postal],
      ['Établissement localité', :localite],
      ['Établissement code INSEE localité', :code_insee_localite],
      ['Entreprise SIREN', :entreprise_siren],
      ['Entreprise capital social', :entreprise_capital_social],
      ['Entreprise numero TVA intracommunautaire', :entreprise_numero_tva_intracommunautaire],
      ['Entreprise forme juridique', :entreprise_forme_juridique],
      ['Entreprise forme juridique code', :entreprise_forme_juridique_code],
      ['Entreprise nom commercial', :entreprise_nom_commercial],
      ['Entreprise raison sociale', :entreprise_raison_sociale],
      ['Entreprise SIRET siège social', :entreprise_siret_siege_social],
      ['Entreprise code effectif entreprise', :entreprise_code_effectif_entreprise],
      ['Entreprise date de création', :entreprise_date_creation],
      ['Entreprise nom', :entreprise_nom],
      ['Entreprise prénom', :entreprise_prenom],
      ['Association RNA', :association_rna],
      ['Association titre', :association_titre],
      ['Association objet', :association_objet],
      ['Association date de création', :association_date_creation],
      ['Association date de déclaration', :association_date_declaration],
      ['Association date de publication', :association_date_publication]
    ]
  end

  def siren
    entreprise_siren
  end

  def geo_adresse
    [numero_voie, type_voie, nom_voie, complement_adresse, code_postal, localite].join(' ')
  end

  def inline_adresse
    # squeeze needed because of space in excess in the data
    [
      "#{numero_voie} #{type_voie} #{nom_voie}",
      complement_adresse,
      "#{code_postal} #{localite}"
    ].reject(&:blank?).join(', ').squeeze(' ')
  end

  def association?
    association_rna.present?
  end

  def entreprise
    Entreprise.new(
      siren: entreprise_siren,
      capital_social: entreprise_capital_social,
      numero_tva_intracommunautaire: entreprise_numero_tva_intracommunautaire,
      forme_juridique: entreprise_forme_juridique,
      forme_juridique_code: entreprise_forme_juridique_code,
      nom_commercial: entreprise_nom_commercial,
      raison_sociale: entreprise_raison_sociale,
      siret_siege_social: entreprise_siret_siege_social,
      code_effectif_entreprise: entreprise_code_effectif_entreprise,
      date_creation: entreprise_date_creation,
      nom: entreprise_nom,
      prenom: entreprise_prenom,
      inline_adresse: inline_adresse
    )
  end

  private

  def dossier_id_for_export
    if dossier_id
      dossier_id.to_s
    elsif champ
      champ.dossier_id.to_s
    end
  end

  def libelle_for_export
    champ&.libelle
  end
end
