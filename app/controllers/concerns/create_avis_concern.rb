module CreateAvisConcern
  extend ActiveSupport::Concern

  private

  def create_avis_from_params(dossier, confidentiel = false)
    confidentiel ||= create_avis_params[:confidentiel]

    # Because of a limitation of the email_field rails helper,
    # the :emails parameter is a 1-element array.
    # Hence the call to first
    # https://github.com/rails/rails/issues/17225
    emails = create_avis_params[:emails].first.split(',').map(&:strip)

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

    persisted, failed = create_results.partition(&:persisted?)

    if persisted.any?
      sent_emails_addresses = persisted.map(&:email_to_display).join(", ")
      flash.notice = "Une demande d'avis a été envoyée à #{sent_emails_addresses}"
    end

    if failed.any?
      flash.now.alert = failed
        .select { |avis| avis.errors.present? }
        .map { |avis| "#{avis.email} : #{avis.errors.full_messages.join(', ')}" }

      # When an error occurs, return the avis back to the controller
      # to give the user a chance to correct and resubmit
      Avis.new(create_avis_params.merge(emails: [failed.map(&:email).join(", ")]))
    else
      nil
    end
  end

  def create_avis_params
    params.require(:avis).permit(:introduction, :confidentiel, emails: [])
  end
end
