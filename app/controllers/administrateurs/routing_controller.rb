module Administrateurs
  class RoutingController < AdministrateurController
    include Logic

    before_action :retrieve_procedure

    def update
      left = targeted_champ

      right = targeted_champ_changed? ? empty : value

      new_routing_rule = case operator_name
      when Eq.name
        ds_eq(left, right)
      when NotEq.name
        ds_not_eq(left, right)
      end
      groupe_instructeur.update!(routing_rule: new_routing_rule)
    end

    def update_defaut_groupe_instructeur
      new_defaut = @procedure.groupe_instructeurs.find(defaut_groupe_instructeur_id)
      @procedure.update!(defaut_groupe_instructeur: new_defaut)
    end

    private

    def targeted_champ_changed?
      targeted_champ != groupe_instructeur.routing_rule&.left
    end

    def targeted_champ
      Logic.from_json(params[:targeted_champ])
    end

    def operator_name
      params[:operator_name]
    end

    def value
      Logic.from_json(params[:value])
    end

    def groupe_instructeur
      @groupe_instructeur ||= @procedure.groupe_instructeurs.find(groupe_instructeur_id)
    end

    def groupe_instructeur_id
      params[:groupe_instructeur_id]
    end

    def defaut_groupe_instructeur_id
      params[:defaut_groupe_instructeur_id]
    end
  end
end
