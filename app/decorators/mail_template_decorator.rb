class MailTemplateDecorator < Draper::Decorator
  delegate_all

  def name
    case object.type
    when "MailReceived"
      "E-mail d'accusé de réception"
      object.type
    end
  end
end
