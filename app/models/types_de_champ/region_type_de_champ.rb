class TypesDeChamp::RegionTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def libelle_for_export(index)
    [libelle, "#{libelle} (Code)"][index]
  end
end
