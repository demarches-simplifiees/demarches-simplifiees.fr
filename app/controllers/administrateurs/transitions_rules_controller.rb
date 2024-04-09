module Administrateurs
  class TransitionsRulesController < AdministrateurController
    before_action :retrieve_procedure

    def edit
    end

    def add_row
      condition = Logic.add_empty_condition_to(revision.transitions_rules)
      revision.update!(transitions_rules: condition)
      @transitions_rules_component = build_transition_rule_component
    end

    def delete_row
      condition = condition_form.delete_row(row_index).to_condition
      revision.update!(transitions_rules: condition)

      @transitions_rules_component = build_transition_rule_component
    end

    def update
      condition = condition_form.to_condition
      revision.update!(transitions_rules: condition)

      @transitions_rules_component = build_transition_rule_component
    end

    def change_targeted_champ
      condition = condition_form.change_champ(row_index).to_condition
      revision.update!(transitions_rules: condition)

      @transitions_rules_component = build_transition_rule_component
    end

    private

    def build_transition_rule_component
      Conditions::TransitionsRulesComponent.new(revision:)
    end

    def revision
      @procedure.draft_revision
    end

    def condition_form
      ConditionForm.new(transitions_rules_params.merge(source_tdcs: revision.types_de_champ_public))
    end

    def transitions_rules_params
      params
        .require(:procedure_revision)
        .require(:condition_form)
        .permit(:top_operator_name, rows: [:targeted_champ, :operator_name, :value])
    end

    def row_index
      params[:row_index].to_i
    end
  end
end
