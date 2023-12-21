class TypesDeChamp::AddressTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def tags_for_template
    tags = super
    stable_id = @type_de_champ.stable_id
    tags.push(
      {
        libelle: "#{TagsSubstitutionConcern::TagsParser.normalize(libelle)} (Département)",
        id: "tdc#{stable_id}/departement",
        description: "#{description} (Département)",
        lambda: -> (champs) { champs.find { _1.stable_id == stable_id }&.departement_code_and_name }
      },
      {
        libelle: "#{TagsSubstitutionConcern::TagsParser.normalize(libelle)} (Commune)",
        id: "tdc#{stable_id}/commune",
        description: "#{description} (Commune)",
        lambda: -> (champs) { champs.find { _1.stable_id == stable_id }&.commune_name }
      }
    )
    tags
  end
end
