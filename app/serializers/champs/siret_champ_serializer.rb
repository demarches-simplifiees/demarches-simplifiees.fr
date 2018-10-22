class Champs::SiretChampSerializer < ChampSerializer
  has_one :etablissement
  has_one :entreprise

  def etablissement
    object.etablissement
  end

  def entreprise
    object.etablissement&.entreprise
  end
end
