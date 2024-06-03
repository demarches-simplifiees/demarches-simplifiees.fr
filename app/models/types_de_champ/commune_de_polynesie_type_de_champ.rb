class TypesDeChamp::CommuneDePolynesieTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Code postal)",
                 description: "#{description} (Code postal)",
                 path: :code_postal,
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
    [libelle, "#{libelle} (Code postal)", "#{libelle} (Ile)", "#{libelle} (Archipel)"][index]
  end
end
