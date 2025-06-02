# frozen_string_literal: true

class Champs::SiretChamp < Champ
  include SiretChampEtablissementFetchableConcern

  validate :validate_siret_length

  def search_terms
    etablissement.present? ? etablissement.search_terms : [value]
  end

  def mandatory_blank?
    mandatory? && Siret.new(siret: value).invalid?
  end

  private

  def validate_siret_length
    return if value.blank?

    if value.length < 9
      errors.add(:value, "Veuillez selectionner un des établissements")
    end
  end
end
