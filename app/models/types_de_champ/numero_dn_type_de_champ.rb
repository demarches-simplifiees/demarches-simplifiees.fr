class TypesDeChamp::NumeroDnTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def tags_for_template
    tags = super
    tdc = @type_de_champ
    tags.push(
      {
        libelle: "#{libelle}/numero_dn",
        description: "#{description} (Numero DN)",
        lambda: -> (champs) {
          champs
            .find { |champ| champ.type_de_champ == tdc }
            &.numero_dn
        }
      }
    )
    tags.push(
      {
        libelle: "#{libelle}/date_de_naissance",
        description: "#{description} (date de naissance)",
        lambda: -> (champs) {
          champs
            .find { |champ| champ.type_de_champ == tdc }
            &.date_de_naissance
        }
      }
    )
    tags
  end
end
