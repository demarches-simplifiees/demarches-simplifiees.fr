module Mails
  class RefusedMail < ApplicationRecord
    include MailTemplateConcern

    SLUG = "refused_mail"
    TEMPLATE_NAME = "mails/refused_mail"
    DISPLAYED_NAME = 'Accusé de rejet du dossier'
    DEFAULT_OBJECT = 'Votre dossier TPS nº --numero_dossier-- a été refusé'
    ALLOWED_TAGS = [TAG_NUMERO_DOSSIER, TAG_LIEN_DOSSIER, TAG_LIBELLE_PROCEDURE, TAG_DATE_DE_DECISION, TAG_MOTIVATION]
  end
end
