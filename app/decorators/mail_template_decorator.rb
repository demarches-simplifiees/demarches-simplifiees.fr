class MailTemplateDecorator < Draper::Decorator
  delegate_all

  def name
    case object.type
    when "MailReceived"
      "E-mail d'accusé de réception"
    when "MailValidated"
      "E-mail de validation"
    else
      object.type
    end
  end
end
