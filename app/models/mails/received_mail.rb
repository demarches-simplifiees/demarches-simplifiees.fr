module Mails
  class ReceivedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "received_mail"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/received_mail"
    DISPLAYED_NAME = 'Accusé de passage en instruction'
    DEFAULT_SUBJECT = "Votre dossier #{SITE_NAME} nº --numéro du dossier-- va être instruit"
    DOSSIER_STATE = Dossier.states.fetch(:en_instruction)
  end
end
