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

      redirect_to manager_groupe_gestionnaire_path(groupe_gestionnaire)
    end

    def remove_gestionnaire
      if !groupe_gestionnaire.root_groupe_gestionnaire? || groupe_gestionnaire.gestionnaires.one?
        flash[:alert] = "Suppression impossible : il doit y avoir au moins un gestionnaire dans le groupe racine"
      else
        gestionnaire = Gestionnaire.find(gestionnaire_id)
        if groupe_gestionnaire.remove(gestionnaire)
          flash[:notice] = "Le gestionnaire « #{gestionnaire.email} » a été retiré du groupe."
          GroupeGestionnaireMailer
            .notify_removed_gestionnaire(groupe_gestionnaire, gestionnaire, current_super_admin.email)
            .deliver_later
        else
          flash[:alert] = "Le gestionnaire « #{gestionnaire.email} » n’est pas dans le groupe."
        end
      end

      redirect_to manager_groupe_gestionnaire_path(groupe_gestionnaire)
    end

    private

    def groupe_gestionnaire
      @groupe_gestionnaire ||= GroupeGestionnaire.find(params[:id])
    end

    def gestionnaire_id
      params[:gestionnaire][:id]
    end
  end
end
