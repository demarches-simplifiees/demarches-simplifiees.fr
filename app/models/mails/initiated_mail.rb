module Mails
  class InitiatedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "initiated_mail"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/initiated_mail"
    DISPLAYED_NAME = 'Accusé de réception'
    DEFAULT_SUBJECT = 'Votre dossier nº --numéro du dossier-- a bien été reçu (--libellé démarche--)'
    DOSSIER_STATE = Dossier.states.fetch(:en_construction)
  end
end
