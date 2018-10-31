module CreateAvisConcern
  extend ActiveSupport::Concern

  private

  def create_avis_from_params(dossier, confidentiel = false)
    confidentiel ||= create_avis_params[:confidentiel]
    emails = create_avis_params[:emails].split(',').map(&:strip)

    create_results = Avis.create(
      emails.map do |email|
        {
          email: email,
          introduction: create_avis_params[:introduction],
          claimant: current_gestionnaire,
          dossier: dossier,
          confidentiel: confidentiel
        }
      end
    )

    if create_results.all?(&:persisted?)
      sent_emails_addresses = create_results.map(&:email_to_display).join(", ")
      flash.notice = "Une demande d'avis a été envoyée à #{sent_emails_addresses}"

      nil
    else
      flash.now.alert = create_results
        .map(&:errors)
        .reject(&:empty?)
        .map(&:full_messages)
        .flatten

      # When an error occurs, return the avis back to the controller
      # to give the user a chance to correct and resubmit
      Avis.new(create_avis_params)
    end
  end

  def create_avis_params
    params.require(:avis).permit(:emails, :introduction, :confidentiel)
  end
end
