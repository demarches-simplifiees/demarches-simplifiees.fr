module Administrateurs
  class RoutingController < AdministrateurController
    include Logic

    before_action :retrieve_procedure

    def update
      left = targeted_champ
      right = value

      groupe_instructeur.update!(routing_rule: ds_eq(left, right))
    end

    private

    def targeted_champ
      Logic.from_json(routing_params[:targeted_champ])
    end

    def value
      Logic.from_json(routing_params[:value])
    end

    def groupe_instructeur
      @groupe_instructeur ||= @procedure.groupe_instructeurs.find(groupe_instructeur_id)
    end

    def groupe_instructeur_id
      routing_params[:groupe_instructeur_id]
    end

    def routing_params
      params.permit(:targeted_champ, :value, :groupe_instructeur_id)
    end
  end
end
