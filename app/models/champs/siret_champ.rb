class Champs::SiretChamp < Champ
  def search_terms
    etablissement.present? ? etablissement.search_terms : [value]
  end
end
