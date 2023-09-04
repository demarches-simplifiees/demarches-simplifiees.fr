module Manager
  class GroupeGestionnairesController < Manager::ApplicationController
    def add_gestionnaire
      emails = (params['emails'].presence || '').split(',').to_json
      emails = JSON.parse(emails).map { EmailSanitizableConcern::EmailSanitizer.sanitize(_1) }

      gestionnaires, invalid_emails = groupe_gestionnaire.add_gestionnaires(emails:)

      if invalid_emails.present?
        flash[:alert] = t('.wrong_address',
          count: invalid_emails.size,
          emails: invalid_emails)
      end

      if gestionnaires.present?
        flash[:notice] = "Les gestionnaires ont bien été affectés au groupe d'administrateurs"

        GroupeGestionnaireMailer
          .notify_added_gestionnaires(groupe_gestionnaire, gestionnaires, current_super_admin.email)
          .deliver_later
      end

      redirect_to manager_groupe_gestionnaires_path(groupe_gestionnaire)
    end

    private

    def groupe_gestionnaire
      @groupe_gestionnaire ||= GroupeGestionnaire.find(params[:id])
    end
  end
end
