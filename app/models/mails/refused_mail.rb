module Mails
  class RefusedMail < ApplicationRecord
    include MailTemplateConcern

    DISPLAYED_NAME = 'Accusé de rejet du dossier'
    DEFAULT_OBJECT = 'Votre dossier TPS N°--numero_dossier-- a été refusé'

  end
end
