# frozen_string_literal: true

class Referentiels::ReferentielPrefillComponent < Referentiels::MappingFormBase
  delegate :referentiel_mapping,
           :referentiel_mapping_prefillable,
           to: :type_de_champ

  MAPPING_TYPE_TO_TYPE_DE_CHAMP = {
    Referentiels::MappingFormComponent::TYPES[:string] => %w[text textarea engagement_juridique dossier_link email phone iban siret drop_down_list formatted],
    Referentiels::MappingFormComponent::TYPES[:decimal_number] => %w[decimal_number],
    Referentiels::MappingFormComponent::TYPES[:integer_number] => %w[integer_number],
    Referentiels::MappingFormComponent::TYPES[:boolean] => %w[checkbox yes_no],
    Referentiels::MappingFormComponent::TYPES[:date] => %w[date],
    Referentiels::MappingFormComponent::TYPES[:datetime] => %w[datetime],
    Referentiels::MappingFormComponent::TYPES[:array] => %w[multiple_drop_down_list]
  }.freeze

  def source_tdcs
    if type_de_champ.public?
      @source_tdcs ||= procedure.draft_revision.types_de_champ_for
    else
      @source_tdcs ||= procedure.draft_revision.types_de_champ_for(scope: :private)
    end
  end

  def prefill_stable_id_tag(jsonpath, mapping_opts)
    tdcs = tdc_targets(mapping_opts)
    selected = lookup_existing_value(jsonpath, "prefill_stable_id")
    options = type_de_champ.public? ? grouped_options_for_select(tdcs, selected) : options_for_select(tdcs, selected)
    select_tag(
      attribute_name(jsonpath, "prefill_stable_id"),
      options,
      class: "fr-select"
    )
  end

  private

  def tdc_targets(referentiel_mapping_element)
    mapping_type = referentiel_mapping_element[:type]
    allowed_types = MAPPING_TYPE_TO_TYPE_DE_CHAMP[mapping_type.to_sym] || []
    source_tdcs
      .each_with_object({ "Champs" => [], "Annotations privées" => [] }) do |tdc, grouped_tdcs|
        next if tdc.stable_id == @type_de_champ.stable_id
        next unless allowed_types.include?(tdc.type_champ)

        grouped_tdcs[tdc.public? ? "Champs" : "Annotations privées"] << [tdc.libelle_with_parent(@procedure.draft_revision), tdc.stable_id]
      end
      .then { type_de_champ.public? ? it : it["Annotations privées"] }
  end

  def render?
    referentiel_mapping_prefillable.any?
  end
end
