module Administrateurs
  class ProcedureAdministrateursController < AdministrateurController
    before_action :retrieve_procedure, except: [:new]
    before_action :ensure_not_super_admin!, only: [:create]
    def index
      @disabled_as_super_admin = is_administrateur_through_procedure_administration_as_manager?
    end

    def create
      email = params.require(:administrateur)[:email]&.strip&.downcase

      # Find the admin
      administrateur = Administrateur.by_email(email)
      if administrateur.nil?
        flash.alert = "L’administrateur « #{email} » n’existe pas. Invitez-le à demander un compte administrateur à l’adresse <a href=#{DEMANDE_INSCRIPTION_ADMIN_PAGE_URL}>#{DEMANDE_INSCRIPTION_ADMIN_PAGE_URL}</a>."
        return
      end

      # Prevent duplicates (also enforced in the database in administrateurs_procedures)
      if @procedure.administrateurs.include?(administrateur)
        flash.alert = "L’administrateur « #{administrateur.email} » est déjà administrateur de « #{@procedure.libelle} »."
        return
      end

      # Actually add the admin
      @procedure.administrateurs << administrateur
      @administrateur = administrateur
      @disabled_as_super_admin = is_administrateur_through_procedure_administration_as_manager?
      flash.notice = "L’administrateur « #{administrateur.email} » a été ajouté à la démarche « #{@procedure.libelle} »."
    end

    def destroy
      administrateur = @procedure.administrateurs.find(params[:id])

      # Prevent self-removal (Also enforced in the UI)
      if administrateur == current_administrateur
        flash.alert = "Vous ne pouvez pas vous retirer vous-même d’une démarche."
        return
      end

      # Actually remove the admin
      @procedure.administrateurs.delete(administrateur)
      @administrateur = administrateur
      flash.notice = "L’administrateur \« #{administrateur.email} » a été retiré de la démarche « #{@procedure.libelle} »."
    rescue ActiveRecord::ActiveRecordError => e
      flash.alert = e.message
    end
  end
end
