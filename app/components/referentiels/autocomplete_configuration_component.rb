# frozen_string_literal: true

class Referentiels::AutocompleteConfigurationComponent < Referentiels::MappingFormBase
  def back_url
    edit_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, referentiel.id)
  end

  def form_url
    update_autocomplete_configuration_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, referentiel.id)
  end

  def autocomplete_datasource
    return nil unless referentiel.datasource

    JsonPath.on(referentiel.last_response_body, referentiel.datasource).first.first
  end

  def autocomplete_template
    referentiel.template
  end

  def select_datasource_radio_tag(jsonpath)
    attribute_name = "referentiel[autocomplete_configuration][datasource]"

    tag.div(class: "fr-radio-group") do
      safe_join([
        radio_button_tag(
          attribute_name,
          jsonpath,
          referentiel.autocomplete_configuration.fetch("datasource", nil) == jsonpath,
          class: "fr-radio"
        ),
        label_tag(attribute_name, class: "fr-label", aria: { hidden: true }) do
          safe_join([
            sanitize("&nbsp;"),
            tag.span("Utiliser ce champ pour l'autocomplétion", class: "hidden")
          ])
        end
      ])
    end
  end

  def select_datasource_property_tag(jsonpath)
    attribute_name = "referentiel[autocomplete_configuration][property]"

    tag.div(class: "fr-radio-group") do
      safe_join([
        radio_button_tag(
          attribute_name,
          jsonpath,
          referentiel.autocomplete_configuration.fetch("datasource_properties", nil) == jsonpath,
          class: "fr-radio"
        ),
        label_tag(attribute_name, class: "fr-label", aria: { hidden: true }) do
          safe_join([
            sanitize("&nbsp;"),
            tag.span("Propriété du champ pour l'autocomplétion", class: "hidden")
          ])
        end
      ])
    end
  end

  def tags
    {
      properties: autocomplete_datasource.keys.map do |jsonpath|
        {
          libelle: jsonpath,
          id: jsonpath
        }
      end
    }
  end

  def form_options
    {
      method: :patch,
      data: {
        # controller: "autosubmit",
        # turbo: true
      }
    }
  end

  def last_request_arrays
    # raise referentiel.last_response_body.inspect
    JSONPathUtil.array_paths_with_examples(referentiel.last_response_body)
  end
end
