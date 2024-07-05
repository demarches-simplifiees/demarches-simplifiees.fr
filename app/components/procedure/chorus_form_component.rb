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

  def selected_key(attribute_name)
    items(attribute_name).first&.dig(:value)
  end

  def items(attribute_name)
    label = format_displayed_value(attribute_name)
    data = format_hidden_value(attribute_name)
    if label.present?
      [{ label:, value: label, data: }]
    else
      []
    end
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
      @chorus_configuration.centre_de_cout
    when :domaine_fonctionnel
      @chorus_configuration.domaine_fonctionnel
    when :referentiel_de_programmation
      @chorus_configuration.referentiel_de_programmation
    else
      raise 'unknown attribute_name'
    end
  end

  def react_props(name, chorus_configuration_attribute, datasource_endpoint)
    {
      name:,
      selected_key: selected_key(chorus_configuration_attribute),
      items: items(chorus_configuration_attribute),
      loader: datasource_endpoint,
      id: chorus_configuration_attribute
    }
  end
end
