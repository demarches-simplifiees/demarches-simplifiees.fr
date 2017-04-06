module Mails
  class ClosedMail < ActiveRecord::Base
    include MailTemplateConcern

    DISPLAYED_NAME = "Accusé d'acceptation"
    DEFAULT_OBJECT = 'Votre dossier TPS Nº--numero_dossier-- a été accepté'

  end
end
