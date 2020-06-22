module CreateAvisConcern
  extend ActiveSupport::Concern

  private

  def create_avis_from_params(dossier, confidentiel = false)
    confidentiel ||= create_avis_params[:confidentiel]

    # Because of a limitation of the email_field rails helper,
    # the :emails parameter is a 1-element array.
    # Hence the call to first
    # https://github.com/rails/rails/issues/17225
    expert_emails = create_avis_params[:emails].first.split(',').map(&:strip)
    allowed_dossiers = [dossier]

    if create_avis_params[:invite_linked_dossiers].present?
      allowed_dossiers += dossier.linked_dossiers_for(current_instructeur)
    end

    create_results = Avis.create(
      expert_emails.flat_map do |email|
        allowed_dossiers.map do |dossier|
          {
            email: email,
            introduction: create_avis_params[:introduction],
            introduction_file: create_avis_params[:introduction_file],
            claimant: current_instructeur,
            dossier: dossier,
            confidentiel: confidentiel
          }
        end
      end
    )

    persisted, failed = create_results.partition(&:persisted?)

    if persisted.any?
      sent_emails_addresses = []
      persisted.each do |avis|
        avis.dossier.demander_un_avis!(avis)

        if avis.dossier == dossier
          AvisMailer.avis_invitation(avis).deliver_later
          sent_emails_addresses << avis.email_to_display
        end
      end
      flash.notice = "Une demande d'avis a été envoyée à #{sent_emails_addresses.uniq.join(", ")}"
    end

    if failed.any?
      flash.now.alert = failed
        .filter { |avis| avis.errors.present? }
        .map { |avis| "#{avis.email} : #{avis.errors.full_messages.join(', ')}" }

      # When an error occurs, return the avis back to the controller
      # to give the user a chance to correct and resubmit
      Avis.new(create_avis_params.merge(emails: [failed.map(&:email).uniq.join(", ")]))
    else
      nil
    end
  end

  def create_avis_params
    params.require(:avis).permit(:introduction_file, :introduction, :confidentiel, :invite_linked_dossiers, emails: [])
  end
end
