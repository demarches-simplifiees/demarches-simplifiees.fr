module Mails
  class ReceivedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "received_mail"
    TEMPLATE_NAME = "mails/received_mail"
    DISPLAYED_NAME = 'Accusé de passage en instruction'
    DEFAULT_SUBJECT = 'Votre dossier TPS nº --numéro du dossier-- va être instruit'
    IS_DOSSIER_TERMINE = false
  end
end
