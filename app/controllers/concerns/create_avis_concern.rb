module CreateAvisConcern
  extend ActiveSupport::Concern

  private

  def create_avis_from_params(dossier, confidentiel = false)
    confidentiel ||= create_avis_params[:confidentiel]
    avis = Avis.new(create_avis_params.merge(claimant: current_gestionnaire, dossier: dossier, confidentiel: confidentiel))

    if avis.save
      flash.notice = "Une demande d'avis a été envoyée à #{avis.email_to_display}"

      nil
    else
      flash.now.alert = @avis.errors.full_messages

      # When an error occurs, return the avis back to the controller
      # to give the user a chance to correct and resubmit
      avis
    end
  end

  def create_avis_params
    params.require(:avis).permit(:email, :introduction, :confidentiel)
  end
end
