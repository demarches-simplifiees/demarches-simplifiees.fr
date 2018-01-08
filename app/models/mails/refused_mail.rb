module Mails
  class RefusedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "refused_mail"
    TEMPLATE_NAME = "mails/refused_mail"
    DISPLAYED_NAME = 'Accusé de rejet du dossier'
    DEFAULT_SUBJECT = 'Votre dossier TPS nº --numéro du dossier-- a été refusé'
    IS_DOSSIER_TERMINE = true
  end
end
