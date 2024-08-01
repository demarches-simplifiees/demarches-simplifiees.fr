# frozen_string_literal: true

class ResendAttestationMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def resend_attestation(dossier)
    to = dossier.user_email_for(:notification)
    subject = "Nouvelle attestation pour votre dossier nº #{dossier.id}"

    mail(to: to, subject: subject, body: body(dossier))
  end

  def self.critical_email?(action_name)
    false
  end

  private

  def body(dossier)
    <<~HEREDOC
      Bonjour,

      L’attestation de votre dossier nº #{dossier.id} (démarche "#{dossier.procedure.libelle}") a été modifiée.

      Votre nouvelle attestation est disponible à l'adresse suivante :
      #{attestation_dossier_url(dossier)}

      Cordialement,

      L’équipe #{Current.application_name}
    HEREDOC
  end
end
