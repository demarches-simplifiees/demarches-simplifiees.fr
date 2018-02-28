module Mails
  class ReceivedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "received_mail"
    TEMPLATE_NAME = "mails/received_mail"
    DISPLAYED_NAME = 'Accusé de passage en instruction'
    DEFAULT_SUBJECT = 'Votre dossier demarches-simplifiees.fr nº --numéro du dossier-- va être instruit'
    DOSSIER_STATE = 'en_instruction'
  end
end
