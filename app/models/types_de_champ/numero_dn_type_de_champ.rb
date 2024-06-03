class TypesDeChamp::NumeroDnTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Date de naissance)",
                 description: "#{description} (Date de naissance)",
                 path: :date_de_naissance,
                 example: Date.today,
                 maybe_null: public? && !mandatory?
    })
    paths
  end

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
