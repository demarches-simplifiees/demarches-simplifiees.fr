module Mails
  class RefusedMail < ApplicationRecord
    include MailTemplateConcern

    def name
      "Accusé de rejet du dossier"
    end

    def self.default
      obj = "Votre dossier TPS N°--numero_dossier-- a été refusé"
      body = ActionController::Base.new.render_to_string(template: 'notification_mailer/refused_mail')
      RefusedMail.new(object: obj, body: body)
    end
  end
end
