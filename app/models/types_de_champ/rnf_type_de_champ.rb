class TypesDeChamp::RNFTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def libelle_for_export(index)
    [libelle, "#{libelle} (Nom)", "#{libelle} (Adresse)", "#{libelle} (Code insee Ville)", "#{libelle} (Département)"][index]
  end
end
