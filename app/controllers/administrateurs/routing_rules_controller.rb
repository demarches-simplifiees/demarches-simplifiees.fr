module Administrateurs
  class RoutingRulesController < AdministrateurController
    include Logic
    before_action :retrieve_procedure, :retrieve_tdcs
    before_action :retrieve_groupe_instructeur, except: [:update_defaut_groupe_instructeur]

    def update
      condition = condition_form.to_condition
      @groupe_instructeur.update!(routing_rule: condition)

      @routing_rule_component = build_routing_rule_component
    end

    def add_row
      condition = Logic.add_empty_condition_to(@groupe_instructeur.routing_rule)
      @groupe_instructeur.update!(routing_rule: condition)

      @routing_rule_component = build_routing_rule_component
    end

    def delete_row
      condition = condition_form.delete_row(row_index).to_condition
      @groupe_instructeur.update!(routing_rule: condition)

      @routing_rule_component = build_routing_rule_component
    end

    def change_targeted_champ
      condition = condition_form.change_champ(row_index).to_condition
      @groupe_instructeur.update!(routing_rule: condition)

      @routing_rule_component = build_routing_rule_component
    end

    def update_defaut_groupe_instructeur
      new_defaut = @procedure.groupe_instructeurs.find(defaut_groupe_instructeur_id)
      @procedure.update!(defaut_groupe_instructeur: new_defaut)
    end

    private

    def groupe_instructeur_id
      params[:groupe_instructeur_id]
    end

    def defaut_groupe_instructeur_id
      params[:defaut_groupe_instructeur_id]
    end

    def build_routing_rule_component
      Conditions::RoutingRulesComponent.new(
        groupe_instructeur: @groupe_instructeur
      )
    end

    def condition_form
      ConditionForm.new(routing_rule_params.merge({ source_tdcs: @source_tdcs }))
    end

    def retrieve_tdcs
      @source_tdcs = @procedure.active_revision.types_de_champ
    end

    def retrieve_groupe_instructeur
      @groupe_instructeur = @procedure.groupe_instructeurs.find(groupe_instructeur_id)
    end

    def routing_rule_params
      params
        .require(:groupe_instructeur)
        .require(:condition_form)
        .permit(:top_operator_name, rows: [:targeted_champ, :operator_name, :value])
    end

    def row_index
      params[:row_index].to_i
    end
  end
end
