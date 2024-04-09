class Conditions::TransitionsRulesComponent < Conditions::ConditionsComponent
  include Logic

  def initialize(revision:)
    @revision = revision
    @condition = revision.transitions_rules
    @source_tdcs = revision.conditionable_types_de_champ
  end

  private

  def input_prefix
    'procedure_revision[condition_form]'
  end

  def input_id_for(name, row_index)
    "#{@revision.id}-#{name}-#{row_index}"
  end

  def delete_condition_path(row_index)
    delete_row_admin_procedure_transitions_rules_path(@revision.procedure_id, revision_id: @revision.id, row_index:)
  end

  def add_condition_path
    add_row_admin_procedure_transitions_rules_path(@revision.procedure_id, revision_id: @revision.id)
  end
end
