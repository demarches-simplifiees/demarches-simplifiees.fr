class TypesDeChamp::PaysTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  private

  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Code)",
      description: "#{description} (Code)",
      path: :code,
      maybe_null: public? && !mandatory?
    })
    paths
  end
end
