module Manager
  class DemandesController < Manager::ApplicationController
    def index
      @pending_demandes = pending_demandes
    end

    def create_administrateur
      administrateur = current_administration.invite_admin(create_administrateur_params[:email])

      if administrateur.errors.empty?
        PipedriveService.update_person_owner(create_administrateur_params[:person_id], PipedriveService::PIPEDRIVE_CAMILLE_ID)
        flash.notice = "Administrateur créé"
        redirect_to manager_demandes_path
      else
        flash.now.alert = administrateur.errors.full_messages
        @pending_demandes = pending_demandes
        render :index
      end
    end

    private

    def create_administrateur_params
      params.require(:administrateur).permit(:email, :person_id)
    end

    def pending_demandes
      already_approved_emails = Administrateur
        .where(email: demandes.map { |d| d[:email] })
        .pluck(:email)

      demandes.reject { |demande| already_approved_emails.include?(demande[:email]) }
    end

    def demandes
      @demandes ||= PipedriveService.fetch_people_demandes
    end
  end
end
