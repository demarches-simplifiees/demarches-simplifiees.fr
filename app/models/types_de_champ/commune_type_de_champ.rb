class TypesDeChamp::CommuneTypeDeChamp < TypesDeChamp::TypeDeChampBase
  private

  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Code INSEE)",
      description: "#{description} (Code INSEE)",
      path: :code,
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
