module Mails
  class ClosedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "closed_mail"
    TEMPLATE_NAME = "mails/closed_mail"
    DISPLAYED_NAME = "Accusé d'acceptation"
    DEFAULT_OBJECT = 'Votre dossier TPS nº --numero_dossier-- a été accepté'
    IS_DOSSIER_TERMINE = true
  end
end
