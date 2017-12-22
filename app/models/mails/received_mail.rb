module Mails
  class ReceivedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "received_mail"
    TEMPLATE_NAME = "mails/received_mail"
    DISPLAYED_NAME = 'Accusé de passage en instruction'
    DEFAULT_OBJECT = 'Votre dossier TPS nº --numero_dossier-- va être instruit'
    IS_FOR_CLOSED_DOSSIER = false
  end
end
