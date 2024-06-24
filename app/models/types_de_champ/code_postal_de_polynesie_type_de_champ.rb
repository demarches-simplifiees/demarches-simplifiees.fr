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

  LABELS = ["", " (Commune)", " (Ile)", " (Archipel)"]

  def libelle_for_export(index)
    libelle + LABELS[index]
  end

  class << self
    def champ_value(champ)
      city = APIGeo::API.commune_by_postal_code_city_label(champ.value)
      city ? city[:code_postal].to_s : ''
    end

    def champ_value_for_export(champ, path = :value)
      champ_value_for_tag(champ, path)
    end

    def champ_value_for_tag(champ, path = :value)
      if champ.valid_value.present? && (city = APIGeo::API.commune_by_postal_code_city_label(champ.value))
        path = :code_postal if path == :value
        city[path]
      else
        ''
      end
    end
  end
end
