module Manager
  class DemandesController < Manager::ApplicationController
    def index
      @pending_demandes = pending_demandes
    end

    def create_administrateur
      administrateur = current_administration.invite_admin(create_administrateur_params[:email])

      if administrateur.errors.empty?
        PipedriveAcceptsDealsJob.perform_later(
          create_administrateur_params[:person_id],
          current_administration.id,
          create_administrateur_params[:stage_id]
        )

        flash.notice = "Administrateur créé"
        redirect_to manager_demandes_path
      else
        flash.now.alert = administrateur.errors.full_messages.to_sentence
        @pending_demandes = pending_demandes
        render :index
      end
    end

    def refuse_administrateur
      PipedriveRefusesDealsJob.perform_later(
        refuse_administrateur_params[:person_id],
        current_administration.id
      )

      AdministrationMailer
        .refuse_admin(refuse_administrateur_params[:email])
        .deliver_later

      flash.notice = "La demande de #{refuse_administrateur_params[:email]} va être refusée"
      redirect_to manager_demandes_path
    end

    private

    def create_administrateur_params
      params.permit(:email, :person_id, :stage_id)
    end

    def refuse_administrateur_params
      params.permit(:email, :person_id)
    end

    def pending_demandes
      already_approved_emails = Administrateur
        .where(email: demandes.map { |d| d[:email] })
        .pluck(:email)

      demandes.reject { |demande| already_approved_emails.include?(demande[:email]) }
    end

    def demandes
      @demandes ||= PipedriveService.get_demandes
    end
  end
end
