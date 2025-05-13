# frozen_string_literal: true

module CreateAvisConcern
  extend ActiveSupport::Concern

  private

  def create_avis_from_params(dossier, instructeur_or_expert, avis_params = nil, confidentiel = false)
    # If no avis_params is passed, fallback to params (used in controllers)
    avis_params ||= params.require(:avis).permit(
      :introduction_file, :introduction, :confidentiel,
      :invite_linked_dossiers, :question_label, emails: []
    )

    # If emails are blank, create an Avis object with errors
    if avis_params[:emails].all?(&:blank?)
      avis = Avis.new(avis_params)
      errors = avis.errors
      errors.add(:emails, :blank)

      # Log the error instead of using flash
      Rails.logger.error "Avis creation failed due to blank emails: #{errors.full_messages}"

      return avis
    end

    # If confidentiel is not passed, fall back to the value in avis_params
    confidentiel ||= avis_params[:confidentiel]

    # Process emails to remove spaces and ensure they are lowercase
    expert_emails = avis_params[:emails].presence || []
    expert_emails = expert_emails.map(&:strip).map(&:downcase)

    allowed_dossiers = [dossier]

    # Add linked dossiers to the allowed dossiers list if specified in params
    if avis_params[:invite_linked_dossiers].present?
      allowed_dossiers += dossier.linked_dossiers_for(instructeur_or_expert)
    end

    # If instructeur_or_expert doesn't already follow the dossier, follow it
    if instructeur_or_expert.is_a?(Instructeur) && !instructeur_or_expert.follows.exists?(dossier: dossier)
      instructeur_or_expert.follow(dossier)
    end

    # Create avis records for each expert email
    create_results = Avis.create(
      expert_emails.flat_map do |email|
        user = User.create_or_promote_to_expert(email, SecureRandom.hex)

        allowed_dossiers.map do |dossier|
          experts_procedure = user.valid? ? ExpertsProcedure.find_or_create_by(procedure: dossier.procedure, expert: user.expert) : nil
          {
            email: email,
            introduction: avis_params[:introduction],
            introduction_file: avis_params[:introduction_file],
            claimant: instructeur_or_expert,
            dossier: dossier,
            confidentiel: confidentiel,
            experts_procedure: experts_procedure,
            question_label: avis_params[:question_label]
          }
        end
      end
    )

    # Reload the dossier avis to remove non-persisted avis
    dossier.avis.reload

    # Split the results into persisted and failed
    persisted, failed = create_results.partition(&:persisted?)

    # If any avis were successfully created, send emails
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
          avis.update_column(:email, nil) # Email already verified, set to nil
        end
      end
      # Log success message
      Rails.logger.info "Avis request sent successfully to #{sent_emails_addresses.uniq.join(', ')}"
    end

    # Handle failed avis creation (if any)
    if failed.any?
      # Log the failure details
      failure_messages = failed
        .filter { |avis| avis.errors.present? }
        .map { |avis| "#{avis.email} : #{avis.errors.full_messages_for(:email).join(', ')}" }

      Rails.logger.error "Avis creation failed for: #{failure_messages.join('; ')}"

      # Return the avis back to the controller with errors for correction
      Avis.new(avis_params.merge(emails: [failed.map(&:email).uniq.join(', ')]))
    else
      nil
    end
  end
end
