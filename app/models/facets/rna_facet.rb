class Facets::RNAFacet < Facet
  def id
    "#{table}/#{column}/rna"
  end
end
