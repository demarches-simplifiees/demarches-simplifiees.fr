module Mails
  class ReceivedMail < ActiveRecord::Base
    include MailTemplateConcern

    DISPLAYED_NAME = 'Accusé de passage en instruction'
    DEFAULT_OBJECT = 'Votre dossier TPS Nº--numero_dossier-- va être instruit'

  end
end
