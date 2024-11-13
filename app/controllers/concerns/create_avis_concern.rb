# frozen_string_literal: true

module CreateAvisConcern
  extend ActiveSupport::Concern

  private

  def create_avis_from_params(dossier, instructeur_or_expert, confidentiel = false)
    if create_avis_params[:emails].blank?
      avis = Avis.new(create_avis_params)
      errors = avis.errors
      errors.add(:emails, :blank)

      flash.alert = errors.full_message(:emails, errors[:emails].first)

      return avis
    end

    confidentiel ||= create_avis_params[:confidentiel]
    # Because of a limitation of the email_field rails helper,
    # the :emails parameter is a 1-element array.
    # Hence the call to first
    # https://github.com/rails/rails/issues/17225
    expert_emails = create_avis_params[:emails].presence || []
    expert_emails = expert_emails.map(&:strip).map(&:downcase)
    allowed_dossiers = [dossier]

    if create_avis_params[:invite_linked_dossiers].present?
      allowed_dossiers += dossier.linked_dossiers_for(instructeur_or_expert)
    end

    if (instructeur_or_expert.is_a?(Instructeur)) && !instructeur_or_expert.follows.exists?(dossier: dossier)
      instructeur_or_expert.follow(dossier)
    end

    create_results = Avis.create(
      expert_emails.flat_map do |email|
        user = User.create_or_promote_to_expert(email, SecureRandom.hex)

        allowed_dossiers.map do |dossier|
          experts_procedure = user.valid? ? ExpertsProcedure.find_or_create_by(procedure: dossier.procedure, expert: user.expert) : nil
          {
            email: email,
            introduction: create_avis_params[:introduction],
            introduction_file: create_avis_params[:introduction_file],
            claimant: instructeur_or_expert,
            dossier: dossier,
            confidentiel: confidentiel,
            experts_procedure: experts_procedure,
            question_label: create_avis_params[:question_label]
          }
        end
      end
    )
    dossier.avis.reload # unload non-persisted avis from dossier

    persisted, failed = create_results.partition(&:persisted?)

    if persisted.any?
      dossier.touch(:last_avis_updated_at)
      sent_emails_addresses = []
      persisted.each do |avis|
        avis.dossier.demander_un_avis!(avis)
        if avis.dossier == dossier
          if avis.experts_procedure.notify_on_new_avis?
            if avis.expert.user.unverified_email?
              avis.expert.user.invite_expert_and_send_avis!(avis)
            else
              AvisMailer.avis_invitation(avis).deliver_later
            end
          end
          sent_emails_addresses << avis.expert.email
          # the email format is already verified, we update value to nil
          avis.update_column(:email, nil)
        end
      end
      flash.notice = "Une demande d’avis a été envoyée à #{sent_emails_addresses.uniq.join(", ")}"
    end

    if failed.any?
      flash.now.alert = failed
        .filter { |avis| avis.errors.present? }
        .map { |avis| "#{avis.email} : #{avis.errors.full_messages_for(:email).join(', ')}" }

      # When an error occurs, return the avis back to the controller
      # to give the user a chance to correct and resubmit
      Avis.new(create_avis_params.merge(emails: [failed.map(&:email).uniq.join(", ")]))
    else
      nil
    end
  end

  def create_avis_params
    params.require(:avis).permit(:introduction_file, :introduction, :confidentiel, :invite_linked_dossiers, :question_label, emails: [])
  end
end
