class TypesDeChamp::RNATypeDeChamp < TypesDeChamp::TypeDeChampBase
  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def facets(table:)
    super.concat([
      Facets::RNAFacet.new(
        table:,
        virtual: true,
        column: stable_id,
        label: "#{libelle} – commune",
        type: TypeDeChamp.filter_hash_type(type_champ),
        value_column: "data->'adresse'->>'commune'"
      )
    ])
  end

  class << self
    def champ_value_for_export(champ, path = :value)
      champ.identifier
    end
  end
end
