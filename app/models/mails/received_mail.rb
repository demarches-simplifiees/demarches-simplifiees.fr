module Mails
  class ReceivedMail < ApplicationRecord
    include MailTemplateConcern

    SLUG = "received_mail"
    TEMPLATE_NAME = "mails/received_mail"
    DISPLAYED_NAME = 'Accusé de passage en instruction'
    DEFAULT_OBJECT = 'Votre dossier TPS nº --numero_dossier-- va être instruit'
    ALLOWED_TAGS = [TAG_NUMERO_DOSSIER, TAG_LIEN_DOSSIER, TAG_LIBELLE_PROCEDURE]
  end
end
