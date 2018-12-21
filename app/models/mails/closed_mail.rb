module Mails
  class ClosedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "closed_mail"
    DISPLAYED_NAME = "Accusé d'acceptation"
    DEFAULT_SUBJECT = "Votre dossier #{SITE_NAME} nº --numéro du dossier-- a été accepté"
    DOSSIER_STATE = Dossier.states.fetch(:accepte)

    def self.default_template_name_for_procedure(procedure)
      attestation_template = procedure.attestation_template
      if attestation_template&.activated?
        "notification_mailer/closed_mail_with_attestation"
      else
        "notification_mailer/closed_mail"
      end
    end
  end
end
