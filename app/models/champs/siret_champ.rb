class Champs::SiretChamp < Champ
  include SiretChampEtablissementFetchableConcern

  def search_terms
    etablissement.present? ? etablissement.search_terms : [value]
  end

  def mandatory_blank?
    mandatory? && Siret.new(siret: value).invalid?
  end
end
