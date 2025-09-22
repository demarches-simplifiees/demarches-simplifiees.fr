# frozen_string_literal: true

module Administrateurs
  class ProcedureAdministrateursController < AdministrateurController
    before_action :retrieve_procedure
    before_action :ensure_not_super_admin!, only: [:create]

    def index
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
      flash.notice = "L’administrateur « #{administrateur.email} » a été ajouté à la démarche « #{@procedure.libelle} »."
    end

    def destroy
      admin_to_delete = @procedure.administrateurs.find(params[:id])

      if (@procedure.administrateurs - [admin_to_delete]).filter(&:active?).empty?
        flash.alert = "Il doit rester au moins un administrateur actif."
      else
        begin
          # Actually remove the admin
          @procedure.administrateurs.delete(admin_to_delete)
          @administrateur = admin_to_delete
          flash.notice = "L’administrateur « #{admin_to_delete.email} » a été retiré de la démarche « #{@procedure.libelle} »."

          if current_administrateur == admin_to_delete
            redirect_to admin_procedures_path
          end
        rescue ActiveRecord::ActiveRecordError => e
          flash.alert = e.message
        end
      end
    end
  end
end
