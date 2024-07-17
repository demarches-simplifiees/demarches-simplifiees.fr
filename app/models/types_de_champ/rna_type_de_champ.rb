class TypesDeChamp::RNATypeDeChamp < TypesDeChamp::TypeDeChampBase
  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def search_paths
    super.concat([
      {
        libelle: "#{libelle} – commune",
        path: :"data.commune"
      }
    ])
  end

  class << self
    def champ_value_for_export(champ, path = :value)
      champ.identifier
    end
  end
end
