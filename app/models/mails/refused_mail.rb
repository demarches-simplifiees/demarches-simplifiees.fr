module Mails
  class RefusedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "refused_mail"
    DEFAULT_TEMPLATE_NAME = "mails/refused_mail"
    DISPLAYED_NAME = 'Accusé de rejet du dossier'
    DEFAULT_SUBJECT = 'Votre dossier demarches-simplifiees.fr nº --numéro du dossier-- a été refusé'
    DOSSIER_STATE = 'refuse'
  end
end
