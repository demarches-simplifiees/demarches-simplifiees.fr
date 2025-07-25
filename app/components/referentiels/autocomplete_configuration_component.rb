# frozen_string_literal: true

class Referentiels::AutocompleteConfigurationComponent < Referentiels::MappingFormBase
  def id
    :autocomplete_configuration
  end

  def back_url
    edit_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, referentiel.id)
  end

  def form_url
    update_autocomplete_configuration_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, referentiel.id)
  end

  def datasource
    datasource_jsonpath = referentiel.datasource
    datasource_jsonpath ||= default_datasource

    return nil if datasource_jsonpath.nil?
    JsonPath.on(referentiel.last_response_body, datasource_jsonpath).first.first
  end

  def autocomplete_template
    referentiel.template
  end

  def select_datasource_radio_tag(jsonpath)
    radio_button_tag(
      "referentiel[datasource]",
      jsonpath,
      maybe_datasources.size == 1 ? true : referentiel.autocomplete_configuration.fetch("datasource", nil) == jsonpath
    )
  end

  def tags
    jsonpaths = JSONPathUtil.hash_to_jsonpath(datasource)
    properties = jsonpaths.map do |jsonpath, value|
      {
        libelle: "#{jsonpath} (#{value})",
        id: jsonpath
      }
    end
    { properties: }
  end

  def form_options
    {
      method: :patch,
      data: {
        controller: "autosubmit",
        autosubmit_debounce_delay_value: 1000,
        turbo: true

      },
      html: { novalidate: 'novalidate', id: }
    }
  end

  def maybe_datasources
    JSONPathUtil.array_paths_with_examples(referentiel.last_response_body)
      .sort
      .to_h
  end

  def only_one_datasource?
    maybe_datasources.size == 1
  end

  def default_datasource
    return nil if maybe_datasources.empty?
    maybe_datasources&.keys&.first
  end
end
