class TypesDeChamp::EpciTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def libelle_for_export(index)
    [libelle, "#{libelle} (Code)", "#{libelle} (Département)"][index]
  end
end
