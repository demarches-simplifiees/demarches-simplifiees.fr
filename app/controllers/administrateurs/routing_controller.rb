module Administrateurs
  class RoutingController < AdministrateurController
    include Logic

    before_action :retrieve_procedure

    def update
      left = champ_value(targeted_champ)
      right = parsed_value

      @procedure.groupe_instructeurs.find(groupe_instructeur_id).update!(routing_rule: ds_eq(left, right))
    end

    private

    def targeted_champ
      routing_params[:targeted_champ].to_i
    end

    def value
      routing_params[:value]
    end

    def parsed_value
      term = Logic.from_json(value) rescue nil

      term.presence || constant(value)
    end

    def groupe_instructeur_id
      routing_params[:groupe_instructeur_id]
    end

    def routing_params
      params.permit(:targeted_champ, :value, :groupe_instructeur_id)
    end
  end
end
