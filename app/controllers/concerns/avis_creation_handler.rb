# frozen_string_literal: true

module AvisCreationHandler
  extend ActiveSupport::Concern

  def handle_create_avis(dossier:, user:, params:, success_path:, error_template:, avis_source: nil)
    result = CreateAvisService.call(
      dossier: dossier,
      instructeur_or_expert: user,
      params: params,
      avis_source: avis_source
    )

    flash[:notice] = "Une demande d’avis a été envoyée à #{result.sent_emails.join(', ')}" if result.sent_emails.any?

    if result.failed_avis.any?
      @new_avis = result.avis

      flash.now[:alert] = result.failed_avis.flat_map do |failed_avis|
        if failed_avis.email.blank?
          failed_avis.errors.full_messages_for(:email)
        else
          "#{failed_avis.email} : #{failed_avis.errors.full_messages_for(:email).join(', ')}"
        end
      end.join(' | ')

      render error_template, status: :unprocessable_entity
    else
      redirect_to success_path
    end
  end
end
