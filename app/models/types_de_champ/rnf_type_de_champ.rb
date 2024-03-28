class TypesDeChamp::RNFTypeDeChamp < TypesDeChamp::TextTypeDeChamp
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
      path: :adresse,
      maybe_null: public? && !mandatory?
    })
    paths.push({
      libelle: "#{libelle} (Code INSEE)",
      description: "#{description} (Code INSEE)",
      path: :code_insee,
      maybe_null: public? && !mandatory?
    })
    paths.push({
      libelle: "#{libelle} (Département)",
      description: "#{description} (Département)",
      path: :departement,
      maybe_null: public? && !mandatory?
    })
    paths.push({
      libelle: "#{libelle} (Commune)",
      description: "#{description} (Commune)",
      path: :commune,
      maybe_null: public? && !mandatory?
    })
    paths
  end
end
