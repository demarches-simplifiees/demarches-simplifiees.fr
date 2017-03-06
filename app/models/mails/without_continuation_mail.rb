module Mails
  class WithoutContinuationMail < ApplicationRecord
    include MailTemplateConcern

    def name
      "Accusé de classement sans suite"
    end

    def self.default
      obj = "Votre dossier TPS N°--numero_dossier-- a été classé sans suite"
      body = ActionController::Base.new.render_to_string(template: 'notification_mailer/without_continuation_mail')
      WithoutContinuationMail.new(object: obj, body: body)
    end
  end
end
