class TypesDeChamp::CommuneDePolynesieTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def libelle_for_export(index)
    [libelle, "#{libelle} (Code postal)", "#{libelle} (Ile)", "#{libelle} (Archipel)"][index]
  end
end
