class Facets::RNAFacet < Facet
  def column
    "#{@column}->rna"
  end

  def filtered_ids(dossiers, value)
    dossiers.with_type_de_champ(column)
      .where("champs.data->'adresse'->>'commune' = ?", value)
      .pluck(:id)
  end
end
