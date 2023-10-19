class Procedure::ChorusFormComponent < ApplicationComponent
  attr_reader :procedure

  def initialize(procedure:)
    @procedure = procedure
  end

  def map_attribute_to_autocomplete_endpoint
    {
      centre_de_coup: data_sources_search_centre_couts_path,
      domaine_fonctionnel: data_sources_search_domaine_fonct_path,
      referentiel_de_programmation: data_sources_search_ref_programmation_path
    }
  end
end
