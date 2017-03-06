class ClosedMail < ActiveRecord::Base
  include MailTemplateConcern

  def name
    "Accusé d'acceptation"
  end

  def self.default
    obj = "Votre dossier TPS N°--numero_dossier-- a été accepté"
    body = ActionController::Base.new.render_to_string(template: 'notification_mailer/closed_mail')
    ClosedMail.new(object: obj, body: body)
  end
end
