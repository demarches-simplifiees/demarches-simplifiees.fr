module Mails
  class RefusedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "refused_mail"
    TEMPLATE_NAME = "mails/refused_mail"
    DISPLAYED_NAME = 'Accusé de rejet du dossier'
    DEFAULT_OBJECT = 'Votre dossier TPS nº --numero_dossier-- a été refusé'
    IS_FOR_CLOSED_DOSSIER = true
  end
end
