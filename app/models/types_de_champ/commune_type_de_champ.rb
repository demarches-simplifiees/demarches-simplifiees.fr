class TypesDeChamp::CommuneTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def libelle_for_export(index)
    [libelle, "#{libelle} (Code insee)", "#{libelle} (Département)"][index]
  end
end
