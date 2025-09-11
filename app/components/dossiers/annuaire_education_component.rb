# frozen_string_literal: true

class Dossiers::AnnuaireEducationComponent < ApplicationComponent
  attr_reader :champ

  def initialize(champ:)
    @champ = champ
  end

  def call
    render Dossiers::ExternalChampComponent.new(title:, data:, details:, source:)
  end

  private

  def title = champ.to_s

  def data
    [
      ['Nom de l’établissement', champ.data['nom_etablissement']],
      ['L’identifiant de l’etablissement', champ.data['identifiant_de_l_etablissement']],
      ['SIREN/SIRET', champ.data['siren_siret']]
    ]
      .select { |_, value| value.present? }
  end

  def details
    [
      ['Commune', "#{champ.data['nom_commune']} (#{champ.data['code_commune']})"],
      ['Académie', "#{champ.data['libelle_academie']} (#{champ.data['code_academie']})"],
      ['Nature de l’établissement', "#{champ.data['libelle_nature']} (#{champ.data['code_nature']})"],
      ['Type de contrat privé', type_de_contrat],
      ['Nombre d’élèves', champ.data['nombre_d_eleves']],
      ['Adresse', adresse],
      ['Téléphone', champ.data['telephone']],
      ['Email', champ.data['mail']],
      ['Site internet', champ.data['web']]
    ]
      .select { |_, value| value.present? && value != 'SANS OBJET' }
  end

  def source = "Annuaire de l’Éducation Nationale"

  def type_de_contrat
    champ.data['type_contrat_prive'] if champ.data['type_contrat_prive'] != 'SANS OBJET'
  end

  def adresse
    safe_join([
      champ.data['adresse_1'],
      "#{champ.data['code_postal']} #{champ.data['nom_commune']}",
      "#{champ.data['libelle_region']} (#{champ.data['code_region']})"
    ].compact, tag.br)
  end
end
