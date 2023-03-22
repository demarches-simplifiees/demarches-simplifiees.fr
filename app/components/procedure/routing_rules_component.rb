class Procedure::RoutingRulesComponent < ApplicationComponent
  include Logic

  def initialize(procedure:)
    @procedure = procedure
  end

  def rows
    @procedure.groupe_instructeurs.active.map do |gi|
      [gi.routing_rule&.left, gi.routing_rule&.right, gi.id]
    end
  end

  def targeted_champ_tag(targeted_champ, row_index)
    select_tag(
      'targeted_champ',
      options_for_select(targeted_champs_for_select, selected: targeted_champ&.stable_id),
      id: input_id_for('targeted_champ', row_index)
    )
  end

  def value_tag(targeted_champ, value, row_index)
    select_tag(
      'value',
      options_for_select(values_for_select(targeted_champ), selected: value),
      id: input_id_for('value', row_index)
    )
  end

  def hidden_groupe_instructeur_tag(groupe_instructeur_id)
    hidden_field_tag(
      'groupe_instructeur_id',
      groupe_instructeur_id
    )
  end

  private

  def targeted_champs_for_select
    empty_target_for_select + available_targets_for_select
  end

  def empty_target_for_select
    [[t('.select'), empty.to_json]]
  end

  def available_targets_for_select
    @procedure.published_types_de_champ_public
      .filter { |tdc| [:drop_down_list].include?(tdc.type_champ.to_sym) }
      .map { |tdc| [tdc.libelle, tdc.stable_id] }
  end

  def available_values_for_select(targeted_champ)
    return [] if targeted_champ.nil?
    targeted_champ.options(@procedure.draft_revision.types_de_champ)
  end

  def values_for_select(targeted_champ)
    empty_target_for_select + available_values_for_select(targeted_champ)
  end

  def input_id_for(name, row_index)
    "#{@procedure.id}-#{name}-#{row_index}"
  end
end
