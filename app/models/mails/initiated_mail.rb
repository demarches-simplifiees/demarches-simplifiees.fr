module Mails
  class InitiatedMail < ActiveRecord::Base
    include MailTemplateConcern

    def name
      "Accusé de réception"
    end

    def self.default
      obj = "Votre dossier TPS N°--numero_dossier-- a été bien reçu"
      body = ActionController::Base.new.render_to_string(template: 'notification_mailer/initiated_mail')
      InitiatedMail.new(object: obj, body: body)
    end
  end
end
