module Manager
  class ProceduresController < Manager::ApplicationController
    #
    # Administrate overrides
    #

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    def scoped_resource
      if unfiltered_list?
        # Don't display discarded demarches in the unfiltered list…
        Procedure.kept
      else
        # … but allow them to be searched and displayed.
        Procedure.with_discarded
      end
    end

    def whitelist
      procedure.whitelist!
      flash[:notice] = "Démarche whitelistée."
      redirect_to manager_procedure_path(procedure)
    end

    def discard
      procedure.discard_and_keep_track!(current_super_admin)

      logger.info("La démarche #{procedure.id} est supprimée par #{current_super_admin.email}")
      flash[:notice] = "La démarche #{procedure.id} a été supprimée."

      redirect_to manager_procedure_path(procedure)
    end

    def restore
      procedure.restore(current_super_admin)

      flash[:notice] = "La démarche #{procedure.id} a été restauré."

      redirect_to manager_procedure_path(procedure)
    end

    def export_mail_brouillons
      dossiers = procedure.dossiers.state_brouillon.includes(:user)
      emails = dossiers.map { |dossier| dossier.user_email_for(:display) }.sort.uniq
      date = Time.zone.now.strftime('%d-%m-%Y')
      send_data(emails.join("\n"), :filename => "brouillons-#{procedure.id}-au-#{date}.csv")
    end

    def add_administrateur
      add_self = params[:email].blank?
      administrateur_email = add_self ? current_super_admin.email : params[:email]
      administrateur = Administrateur.by_email(administrateur_email)
      if administrateur
        AdministrateursProcedure.create(procedure: procedure, administrateur: administrateur, manager: add_self)
        if add_self
          flash[:notice] = "L’administrateur \"#{administrateur_email}\" est ajouté à la démarche pour la journée."
        else
          flash[:notice] = "L’administrateur \"#{administrateur_email}\" est ajouté à la démarche."
        end
      else
        if add_self
          flash[:alert] = "Vous n’êtes pas connecté en tant qu’administrateur."
        else
          flash[:alert] = "L’administrateur \"#{administrateur_email}\" est introuvable."
        end
      end
      redirect_to manager_procedure_path(procedure)
    end

    def delete_administrateur
      administrateur = procedure.administrateurs.find { |admin| admin.email == current_super_admin.email }
      if administrateur.present?
        procedure.administrateurs.delete(administrateur)
      end
      redirect_to manager_procedure_path(procedure)
    end

    def change_piece_justificative_template
      if type_de_champ.update(type_de_champ_params)
        flash[:notice] = "Le modèle est mis à jour."
      else
        flash[:alert] = type_de_champ.errors.full_messages.join(', ')
      end
      redirect_to manager_procedure_path(procedure)
    end

    private

    def procedure
      @procedure ||= Procedure.with_discarded.find(params[:id])
    end

    def type_de_champ
      TypeDeChamp.find(params[:type_de_champ][:id])
    end

    def type_de_champ_params
      params.require(:type_de_champ).permit(:piece_justificative_template)
    end

    def unfiltered_list?
      action_name == "index" && !params[:search]
    end
  end
end
