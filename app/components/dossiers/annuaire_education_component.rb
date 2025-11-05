# frozen_string_literal: true

class Dossiers::AnnuaireEducationComponent < ApplicationComponent
  attr_reader :champ

  def initialize(champ:)
    @champ = champ
  end

  def call
    render Dossiers::ExternalChampComponent.new(data:, details:, source:)
  end

  private

  def data
    return [] if champ.data.blank?

    [
      ['Nom de l’établissement', champ.data['nom_etablissement']],
      ['L’identifiant de l’etablissement', champ.data['identifiant_de_l_etablissement']],
      ['SIREN/SIRET', champ.data['siren_siret']],
    ]
  end

  def details
    return [] if champ.data.blank?

    [
      ['Commune', commune],
      ['Académie', "#{champ.data['libelle_academie']} (#{champ.data['code_academie']})"],
      ['Nature de l’établissement', "#{champ.data['libelle_nature']} (#{champ.data['code_nature']})"],
      ['Type de contrat privé', type_de_contrat],
      ['Nombre d’élèves', champ.data['nombre_d_eleves']],
      ['Adresse', adresse],
      ['Téléphone', champ.data['telephone']],
      ['Email', champ.data['mail']],
      ['Site internet', champ.data['web']],
    ]
  end

  def commune
    if champ.data['nom_commune'].present? && champ.data['code_commune'].present?
      "#{champ.data['nom_commune']} (#{champ.data['code_commune']})"
    elsif champ.data['nom_commune'].present?
      champ.data['nom_commune']
    else
      'Non renseignée'
    end
  end

  def source = "Annuaire de l’Éducation Nationale"

  def type_de_contrat
    champ.data['type_contrat_prive'] if champ.data['type_contrat_prive'] != 'SANS OBJET'
  end

  def adresse
    safe_join([
      champ.data['adresse_1'],
      champ.data.values_at('code_postal', 'nom_commune').compact_blank.join(" "),
      region_libelle_and_code(champ.data),
    ].compact, tag.br)
  end

  def region_libelle_and_code(data)
    if data['libelle_region'].present? && data['code_region'].present?
      "#{data['libelle_region']} (#{data['code_region']})"
    elsif data['libelle_region'].present?
      data['libelle_region']
    end
  end
end
