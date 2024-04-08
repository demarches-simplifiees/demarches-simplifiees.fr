class TypesDeChamp::RNFTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  private

  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Nom)",
      description: "#{description} (Nom)",
      path: :nom,
      maybe_null: public? && !mandatory?
    })
    paths.push({
      libelle: "#{libelle} (Adresse)",
      description: "#{description} (Adresse)",
      path: :address,
      maybe_null: public? && !mandatory?
    })
    paths.push({
      libelle: "#{libelle} (Code INSEE Ville)",
      description: "#{description} (Code INSEE Ville)",
      path: :code_insee,
      maybe_null: public? && !mandatory?
    })
    paths.push({
      libelle: "#{libelle} (Département)",
      description: "#{description} (Département)",
      path: :departement,
      maybe_null: public? && !mandatory?
    })
    paths
  end
end
