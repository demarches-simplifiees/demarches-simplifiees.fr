module Instructeurs
  class InstructeurController < ApplicationController
    before_action :authenticate_instructeur!

    def nav_bar_profile
      :instructeur
    end

    def ensure_not_super_admin!
      if is_super_admin_through_assign_tos_as_manager?
        redirect_back fallback_location: root_url, alert: "Interdit aux super admins", status: 403
      end
    end

    def is_super_admin_through_assign_tos_as_manager?
      current_instructeur.assign_to
        .where(instructeur: current_instructeur,
                                groupe_instructeur: current_instructeur.groupe_instructeurs.where(procedure_id: @procedure.id),
                                manager: true)
        .count
        .positive?
    end
  end
end
