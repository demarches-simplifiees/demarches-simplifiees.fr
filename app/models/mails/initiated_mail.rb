module Mails
  class InitiatedMail < ApplicationRecord
    include MailTemplateConcern

    DISPLAYED_NAME = 'Accusé de réception'
    DEFAULT_OBJECT = 'Votre dossier TPS nº --numero_dossier-- a été bien reçu'
    ALLOWED_TAGS = [TAG_NUMERO_DOSSIER, TAG_LIEN_DOSSIER, TAG_LIBELLE_PROCEDURE]
  end
end
