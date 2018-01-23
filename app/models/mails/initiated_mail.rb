module Mails
  class InitiatedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "initiated_mail"
    TEMPLATE_NAME = "mails/initiated_mail"
    DISPLAYED_NAME = 'Accusé de réception'
    DEFAULT_SUBJECT = 'Votre dossier TPS nº --numéro du dossier-- a bien été reçu'
    DOSSIER_STATE = 'en_construction'
  end
end
