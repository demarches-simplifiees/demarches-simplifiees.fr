class ReceivedMail < ActiveRecord::Base
  include MailTemplateConcern

  def name
    "Accusé de passage en instruction"
  end

  def self.default
    obj = "Votre dossier TPS N°--numero_dossier-- va être instruit"
    body = ActionController::Base.new.render_to_string(template: 'notification_mailer/received_mail')
    ReceivedMail.new(object: obj, body: body)
  end
end
