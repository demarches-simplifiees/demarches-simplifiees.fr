# frozen_string_literal: true

module InstructeurConcern
  extend ActiveSupport::Concern

  included do
    def retrieve_procedure_presentation
      @procedure_presentation ||= current_instructeur.procedure_presentation_for_procedure_id(params[:procedure_id])
    end

    def set_notifications_dossier
      @notifications = DossierNotification.notifications_for_instructeur_dossier(current_instructeur, dossier)
    end
  end
end
