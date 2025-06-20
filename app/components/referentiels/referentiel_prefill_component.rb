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
    @source_tdcs ||= procedure.draft_revision.types_de_champ_for(scope: :public)
  end

  def prefill_stable_id_tag(jsonpath, mapping_opts)
    select_tag(
      attribute_name(jsonpath, "prefill_stable_id"),
      options_for_select(tdc_targets(mapping_opts), lookup_existing_value(jsonpath, "prefill_stable_id")),
      class: "fr-select"
    )
  end

  def prefill_hidden_tag(jsonpath)
    hidden_field_tag(attribute_name(jsonpath, "prefill"), lookup_existing_value(jsonpath, "prefill"))
  end

  private

  def tdc_targets(referentiel_mapping_element)
    mapping_type = referentiel_mapping_element[:type]
    allowed_types = MAPPING_TYPE_TO_TYPE_DE_CHAMP[mapping_type.to_sym] || []

    source_tdcs
      .reject { |it| it.stable_id == @type_de_champ.stable_id }
      .filter { |it| allowed_types.include?(it.type_champ) }
      .map { |it| [it.libelle_with_parent(@procedure.draft_revision), it.stable_id] }
  end

  def render?
    referentiel_mapping_prefillable.any?
  end
end
