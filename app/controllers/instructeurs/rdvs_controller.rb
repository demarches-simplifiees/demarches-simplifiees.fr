# frozen_string_literal: true

module Instructeurs
  class RdvsController < InstructeurController
    before_action :set_dossier

    def create
      reason = params.require(:rdv).permit(:reason)[:reason]
      @rdv = RdvService.new(rdv_connection: current_instructeur.rdv_connection).send_rdv_invitation(dossier: @dossier, reason:)
    end

    def propose_rdv_menu_content_lazy
      if current_instructeur.rdv_connection
        @has_plage_ouvertures = RdvService.new(rdv_connection: current_instructeur.rdv_connection).check_plage_ouvertures
      end
    end

    private

    def set_dossier
      @dossier = current_instructeur.dossiers.find(params[:dossier_id])
    end
  end
end
