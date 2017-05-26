module Mails
  class WithoutContinuationMail < ApplicationRecord
    include MailTemplateConcern

    DISPLAYED_NAME = 'Accusé de classement sans suite'
    DEFAULT_OBJECT = 'Votre dossier TPS nº --numero_dossier-- a été classé sans suite'
    ALLOWED_TAGS = [TAG_NUMERO_DOSSIER, TAG_LIEN_DOSSIER, TAG_LIBELLE_PROCEDURE, TAG_DATE_DE_DECISION]

  end
end
