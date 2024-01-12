module Instructeurs
  class ContactInformationsController < InstructeurController
    def new
      assign_procedure_and_groupe_instructeur
      @contact_information = @groupe_instructeur.build_contact_information
    end

    def create
      assign_procedure_and_groupe_instructeur
      @contact_information = @groupe_instructeur.build_contact_information(contact_information_params)
      if @contact_information.save
        redirect_to_groupe_instructeur("Les informations de contact ont bien été ajoutées")
      else
        flash[:alert] = @contact_information.errors.full_messages
        render :new
      end
    end

    def edit
      assign_procedure_and_groupe_instructeur
      @contact_information = @groupe_instructeur.contact_information
    end

    def update
      assign_procedure_and_groupe_instructeur
      @contact_information = @groupe_instructeur.contact_information
      if @contact_information.update(contact_information_params)
        redirect_to_groupe_instructeur("Les informations de contact ont bien été modifiées")
      else
        flash[:alert] = @contact_information.errors.full_messages
        render :edit
      end
    end

    def destroy
      assign_procedure_and_groupe_instructeur
      @groupe_instructeur.contact_information.destroy
      redirect_to_groupe_instructeur("Les informations de contact ont bien été supprimées")
    end

    private

    def redirect_to_groupe_instructeur(notice)
      if params[:from_admin] == "true"
        redirect_to admin_procedure_groupe_instructeur_path(@procedure, @groupe_instructeur), notice: notice
      else
        redirect_to instructeur_groupe_path(@procedure, @groupe_instructeur), notice: notice
      end
    end

    def assign_procedure_and_groupe_instructeur
      @procedure = current_instructeur.procedures.find params[:procedure_id]
      @groupe_instructeur = current_instructeur.groupe_instructeurs.find params[:groupe_id]
    end

    def contact_information_params
      params.require(:contact_information).permit(:nom, :email, :telephone, :horaires, :adresse)
    end
  end
end
