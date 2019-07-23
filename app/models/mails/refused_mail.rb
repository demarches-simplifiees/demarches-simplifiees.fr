module Mails
  class RefusedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "refused_mail"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/default_templates/refused_mail"
    DISPLAYED_NAME = 'Accusé de rejet du dossier'
    DEFAULT_SUBJECT = 'Votre dossier nº --numéro du dossier-- a été refusé (--libellé démarche--)'
    DOSSIER_STATE = Dossier.states.fetch(:refuse)
  end
end
