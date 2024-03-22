class TypesDeChamp::CommuneTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def libelle_for_export(index)
    [libelle, "#{libelle} (Code insee)", "#{libelle} (Département)"][index]
  end

  def tags_for_template
    tags = super
    stable_id = @type_de_champ.stable_id
    tags.push(
      {
        libelle: "#{TagsSubstitutionConcern::TagsParser.normalize(libelle)} (Département)",
        id: "tdc#{stable_id}/departement",
        description: "#{description} (Département)",
        lambda: -> (champs) { champs.find { _1.stable_id == stable_id }&.departement_code_and_name }
      }
    )
    tags
  end
end
