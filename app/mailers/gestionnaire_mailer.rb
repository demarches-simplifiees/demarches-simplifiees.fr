class GestionnaireMailer < ApplicationMailer
  layout 'mailers/layout'

  def new_gestionnaire(email, password)
    @password = password
    @email = email
    mail(to: email, subject: "Vous avez été nommé accompagnateur sur la plateforme TPS")
  end

  def last_week_overview(gestionnaire)
    headers['X-mailjet-campaign'] = 'last_week_overview'
    overview = gestionnaire.last_week_overview
    @procedure_overviews = overview[:procedure_overviews]
    mail(to: gestionnaire.email, subject: 'Vos activités sur TPS')
  end

  def send_dossier(sender, dossier, recipient)
    @sender = sender
    @dossier = dossier
    subject = "#{sender.email} vous a envoyé le dossier nº #{dossier.id}"

    mail(to: recipient.email, subject: subject)
  end
end
