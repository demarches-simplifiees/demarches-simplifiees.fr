class TypesDeChamp::CodePostalDePolynesieTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Commune)",
                 description: "#{description} (Commune)",
                 path: :commune,
                 example: 1,
                 maybe_null: public? && !mandatory?
    })
    paths.push({
      libelle: "#{libelle} (Ile)",
                 description: "#{description} (Ile)",
                 path: :ile,
                 example: "",
                 maybe_null: public? && !mandatory?
    })
    paths.push({
      libelle: "#{libelle} (Archipel)",
                 description: "#{description} (Archipel)",
                 path: :archipel,
                 example: "",
                 maybe_null: public? && !mandatory?
    })
    paths
  end

  def libelle_for_export(index)
    [libelle, "#{libelle} (Commune)", "#{libelle} (Ile)", "#{libelle} (Archipel)"][index]
  end
end
