# frozen_string_literal: true

module InstructeurConcern
  extend ActiveSupport::Concern

  included do
    def retrieve_procedure_presentation
      @procedure_presentation ||= current_instructeur.procedure_presentation_for_procedure_id(params[:procedure_id])
    end

    def set_notifications
      @notifications_sticker = DossierNotification.notifications_sticker_for_instructeur_dossier(current_instructeur, dossier)
      @notifications = DossierNotification.notifications_for_instructeur_dossier(current_instructeur, dossier)
    end

    def destroy_notification(notification_type)
      DossierNotification.destroy_notification_by_dossier_and_type_and_instructeur(
        dossier,
        notification_type,
        current_instructeur
      )
    end
  end
end
