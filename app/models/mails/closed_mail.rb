module Mails
  class ClosedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "closed_mail"
    TEMPLATE_NAME = "mails/closed_mail"
    DISPLAYED_NAME = "Accusé d'acceptation"
    DEFAULT_SUBJECT = 'Votre dossier TPS nº --numéro du dossier-- a été accepté'
    DOSSIER_STATE = 'accepte'
  end
end
