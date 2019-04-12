module NewAdministrateur
  class ProcedureAdministrateursController < AdministrateurController
    before_action :retrieve_procedure
    before_action :procedure_locked?

    def index
    end

    def create
      email = params.require(:administrateur)[:email]&.strip&.downcase

      # Find the admin
      administrateur = Administrateur.find_by(email: email)
      if administrateur.nil?
        flash.alert = "L’administrateur « #{email} » n’existe pas. Invitez-le à demander un compte administrateur à l’addresse <a href=#{new_demande_url}>#{new_demande_url}</a>."
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
      flash.notice = "L’administrateur « #{administrateur.email} » a été ajouté à la démarche « #{@procedure.libelle} »."
    end

    def destroy
      administrateur = @procedure.administrateurs.find(params[:id])

      # Prevent self-removal (Also enforced in the UI)
      if administrateur == current_administrateur
        flash.error = "Vous ne pouvez pas vous retirez vous-même d’une procédure."
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
