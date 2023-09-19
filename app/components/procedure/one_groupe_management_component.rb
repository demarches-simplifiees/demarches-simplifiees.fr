class Procedure::OneGroupeManagementComponent < ApplicationComponent
  include Logic

  def initialize(revision:, groupe_instructeur:)
    @revision = revision
    @groupe_instructeur = groupe_instructeur
    @procedure = revision.procedure
  end

  private

  def targeted_champ
    @groupe_instructeur.routing_rule&.left || empty
  end

  def value
    @groupe_instructeur.routing_rule&.right || empty
  end

  def targeted_champ_tag
    select_tag(
      'targeted_champ',
      options_for_select(targeted_champs_for_select, selected: targeted_champ.to_json),
      class: 'fr-select'
    )
  end

  def targeted_champs_for_select
    empty_target_for_select + available_targets_for_select
  end

  def empty_target_for_select
    [[t('.select'), empty.to_json]]
  end

  def available_targets_for_select
    @revision
      .routable_types_de_champ
      .map { |tdc| [tdc.libelle, champ_value(tdc.stable_id).to_json] }
  end

  def value_tag
    select_tag(
      'value',
      options_for_select(
        values_for_select(targeted_champ),
        selected: value.to_json
      ),
      class: 'fr-select'
    )
  end

  def values_for_select(targeted_champ)
    (empty_target_for_select + available_values_for_select(targeted_champ))
      # add id to help morph render selected option
      .map { |(libelle, json)| [libelle, json, { id: "option-#{libelle}" }] }
  end

  def available_values_for_select(targeted_champ)
    return [] if targeted_champ.is_a?(Logic::Empty)
    targeted_champ
      .options(@revision.types_de_champ_public)
      .map { |tdc| [tdc.first, constant(tdc.first).to_json] }
  end
end
