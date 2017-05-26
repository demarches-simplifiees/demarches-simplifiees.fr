module Mails
  class ClosedMail < ApplicationRecord
    include MailTemplateConcern

    SLUG = "closed_mail"
    DISPLAYED_NAME = "Accusé d'acceptation"
    DEFAULT_OBJECT = 'Votre dossier TPS nº --numero_dossier-- a été accepté'
    ALLOWED_TAGS = [TAG_NUMERO_DOSSIER, TAG_LIEN_DOSSIER, TAG_LIBELLE_PROCEDURE, TAG_DATE_DE_DECISION]
  end
end
