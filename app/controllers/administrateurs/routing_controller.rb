module Administrateurs
  class RoutingController < AdministrateurController
    include Logic

    before_action :retrieve_procedure

    def update
      left = targeted_champ

      right = targeted_champ_changed? ? empty : value

      groupe_instructeur.update!(routing_rule: ds_eq(left, right))
    end

    def update_defaut_groupe_instructeur
      @procedure.update!(defaut_groupe_instructeur_id: defaut_groupe_instructeur_id)
    end

    private

    def targeted_champ_changed?
      targeted_champ != groupe_instructeur.routing_rule&.left
    end

    def targeted_champ
      Logic.from_json(params[:targeted_champ])
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
