class ResendAttestationMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def resend_attestation(dossier)
    to = dossier.user.email
    subject = "Nouvelle attestation pour votre dossier nº #{dossier.id}"

    mail(to: to, subject: subject, body: body(dossier))
  end

  private

  def body(dossier)
    <<~HEREDOC
      Bonjour,

      L'attestation de votre dossier nº #{dossier.id} (procédure "#{dossier.procedure.libelle}") a été modifiée.

      Votre nouvelle attestation est disponible à l'adresse suivante :
      #{dossier_attestation_url(dossier)}

      Cordialement,

      L’équipe demarches-simplifiees.fr
    HEREDOC
  end
end
