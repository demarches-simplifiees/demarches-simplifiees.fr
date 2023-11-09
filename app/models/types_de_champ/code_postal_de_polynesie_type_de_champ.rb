class TypesDeChamp::CodePostalDePolynesieTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def libelle_for_export(index)
    [libelle, "#{libelle} (Commune)", "#{libelle} (Ile)", "#{libelle} (Archipel)"][index]
  end
end
