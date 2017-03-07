class InitiatedMail < MailTemplate
  def name
    "E-mail d'accusé de réception"
  end

  def self.default
    obj = "[TPS] Accusé de réception pour votre dossier n°--numero_dossier--"
    body = ActionController::Base.new.render_to_string(template: 'notification_mailer/initiated_mail')
    InitiatedMail.new(object: obj, body: body)
  end

  def self.slug
    self.name.parameterize
  end
end
