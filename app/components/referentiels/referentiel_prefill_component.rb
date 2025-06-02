# frozen_string_literal: true

class Referentiels::ReferentielPrefillComponent < Referentiels::MappingFormBase
  delegate :referentiel_mapping,
           :referentiel_mapping_prefillable,
           to: :type_de_champ

  def source_tdcs
    @source_tdcs ||= procedure.draft_revision.types_de_champ_for(scope: :public)
  end

  def prefill_stable_id_tag(jsonpath, mapping_opts)
    select_tag(
      attribute_name(jsonpath, "prefill_stable_id"),
      options_for_select(tdc_targets(mapping_opts), lookup_existing_value(jsonpath, "prefill_stable_id")),
      class: "fr-select"
    )
  end

  private

  def tdc_targets(referentiel_mapping_element)
    if referentiel_mapping_element[:type].in?(Referentiels::MappingFormComponent::TYPES.values)
      source_tdcs.reject { it.stable_id == @type_de_champ.stable_id }
        .map { [it.libelle, it.stable_id] }
    else
      raise ArgumentError.new("unknown mapping type for #{referentiel_mapping_element[:type]}")
    end
  end

  def render?
    referentiel_mapping_prefillable.any?
  end
end
