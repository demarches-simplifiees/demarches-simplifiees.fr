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

  class << self
    def champ_value(champ)
      champ.numero_dn
    end

    def champ_value_for_export(champ, path = :value)
      case path
      when :value
        champ.numero_dn
      when :date_de_naissance
        champ.date_de_naissance&.to_date
      end
    end

    def champ_value_for_tag(champ, path = :value)
      case path
      when :value
        champ.numero_dn || ''
      when :date_de_naissance
        champ.date_de_naissance ? I18n.l(champ.date_de_naissance.to_date, format: '%d %B %Y') : ''
      end
    end
  end
end
