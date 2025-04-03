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

  class << self
    def champ_value(champ)
      city = APIGeo::API.commune_by_city_postal_code(champ.value)
      city ? city[:commune] : ''
    end

    def champ_value_for_export(champ, path = :value)
      champ_value_for_tag(champ, path)
    end

    def champ_value_for_tag(champ, path = :value)
      if champ.value.present? && (city = APIGeo::API.commune_by_city_postal_code(champ.value))
        path = :commune if path == :value
        city[path]
      else
        ''
      end
    end
  end
end
