class TypesDeChamp::AddressTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def paths
    paths = super
    paths.push(
      {
        libelle: "#{libelle} (Département)",
        path: :departement,
        description: "#{description} (Département)"
      },
      {
        libelle: "#{libelle} (Commune)",
        path: :commune,
        description: "#{description} (Commune)"
      }
    )
    paths
  end
end
