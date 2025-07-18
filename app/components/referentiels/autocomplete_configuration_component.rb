# frozen_string_literal: true

class Referentiels::AutocompleteConfigurationComponent < Referentiels::MappingFormBase
  def back_url
    edit_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, referentiel.id)
  end

  def form_url
    autocomplete_configuration_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, referentiel.id)
  end

  def form_options
    {
      method: :patch,
      data: {
        controller: "referentiel-autocomplete-configuration",
        action: "submit->referentiel-autocomplete-configuration#onSubmit"
      }
    }
  end

  def last_request_arrays
    # raise referentiel.last_response_body.inspect
    JSONPathUtil.array_paths_with_examples(referentiel.last_response_body)
  end
end
