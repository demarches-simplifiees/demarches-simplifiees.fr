class MailTemplateDecorator < Draper::Decorator
  delegate_all

  def name
    case object.type
    when "MailReceived"
      "E-mail d'accusé de réception"
    else
      object.type
    end
  end
end
