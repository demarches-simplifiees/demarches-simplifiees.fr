module Mails
  class WithoutContinuationMail < ApplicationRecord
    include MailTemplateConcern

    SLUG = "without_continuation"
    TEMPLATE_NAME = "mails/without_continuation_mail"
    DISPLAYED_NAME = 'Accusé de classement sans suite'
    DEFAULT_OBJECT = 'Votre dossier TPS nº --numero_dossier-- a été classé sans suite'
    ALLOWED_TAGS = [TAG_NUMERO_DOSSIER, TAG_LIEN_DOSSIER, TAG_LIBELLE_PROCEDURE, TAG_DATE_DE_DECISION, TAG_MOTIVATION]
  end
end
