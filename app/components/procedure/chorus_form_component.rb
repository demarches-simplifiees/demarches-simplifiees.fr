class Procedure::ChorusFormComponent < ApplicationComponent
  attr_reader :procedure

  def initialize(procedure:)
    @procedure = procedure
    @chorus_configuration = @procedure.chorus_configuration
  end

  def map_attribute_to_autocomplete_endpoint
    {
      centre_de_cout: data_sources_search_centre_couts_path,
      domaine_fonctionnel: data_sources_search_domaine_fonct_path,
      referentiel_de_programmation: data_sources_search_ref_programmation_path
    }
  end

  def format_displayed_value(attribute_name)
    case attribute_name
    when :centre_de_cout
      ChorusConfiguration.format_centre_de_cout_label(@chorus_configuration.centre_de_cout)
    when :domaine_fonctionnel
      ChorusConfiguration.format_domaine_fonctionnel_label(@chorus_configuration.domaine_fonctionnel)
    when :referentiel_de_programmation
      ChorusConfiguration.format_ref_programmation_label(@chorus_configuration.referentiel_de_programmation)
    else
      raise 'unknown attribute_name'
    end
  end

  def format_hidden_value(attribute_name)
    case attribute_name
    when :centre_de_cout
      @chorus_configuration.centre_de_cout.to_json
    when :domaine_fonctionnel
      @chorus_configuration.domaine_fonctionnel.to_json
    when :referentiel_de_programmation
      @chorus_configuration.referentiel_de_programmation.to_json
    else
      raise 'unknown attribute_name'
    end
  end
end
