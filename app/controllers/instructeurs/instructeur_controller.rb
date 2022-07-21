module Instructeurs
  class InstructeurController < ApplicationController
    before_action :authenticate_instructeur!

    def nav_bar_profile
      :instructeur
    end

    def ensure_not_super_admin!
      if is_instructeur_through_assign_tos_as_manager?
        redirect_back fallback_location: root_url, alert: "Interdit aux super admins", status: 403
      end
    end

    def is_instructeur_through_assign_tos_as_manager?
      procedure_id = params[:procedure_id]

      current_instructeur.assign_to
        .where(instructeur: current_instructeur,
               groupe_instructeur: current_instructeur.groupe_instructeurs.where(procedure_id: procedure_id),
               manager: true)
        .count
        .positive?
    end
  end
end
