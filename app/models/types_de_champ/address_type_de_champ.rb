class TypesDeChamp::AddressTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def libelles_for_export
    path = paths.first
    [[path[:libelle], path[:path]]]
  end

  private

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
