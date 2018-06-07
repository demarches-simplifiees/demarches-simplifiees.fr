class NewAttestationMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def new_attestation(dossier)
    to = dossier.user.email
    subject = "Nouvelle attestation pour votre dossier nº #{dossier.id}"

    mail(to: to, subject: subject, body: body(dossier))
  end

  private

  def body(dossier)
    <<~HEREDOC
      Bonjour,

      Votre dossier nº #{dossier.id} (procédure "#{dossier.procedure.libelle}") a subi, à un moment, un "aller-retour" :
      - Acceptation de votre dossier
      - Passage en instruction du dossier car besoin de le modifier
      - Seconde acceptation de votre dossier

      Suite à cette opération, l'attestation liée à votre dossier n'a pas été regénérée.
      Ce problème est désormais reglé, votre nouvelle attestation est disponible à l'adresse suivante :
      #{dossier_attestation_url(dossier)}

      Cordialement,

      L’équipe demarches-simplifiees.fr
    HEREDOC
  end
end
