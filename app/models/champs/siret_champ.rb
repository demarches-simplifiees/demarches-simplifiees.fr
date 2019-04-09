class Champs::SiretChamp < Champ
  def search_terms
    etablissement.present? ? etablissement.search_terms : [value]
  end

  def mandatory_and_blank?
    mandatory? && Siret.new(siret: value).invalid?
  end
end
