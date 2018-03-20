class GestionnaireMailer < ApplicationMailer
  layout 'mailers/layout'

  def new_gestionnaire(email, password)
    send_mail email, password, "Vous avez été nommé accompagnateur sur demarches-simplifiees.fr"
  end

  def last_week_overview(gestionnaire)
    headers['X-mailjet-campaign'] = 'last_week_overview'
    overview = gestionnaire.last_week_overview
    send_mail gestionnaire.email, overview, 'Vos activités sur demarches-simplifiees.fr'
  end

  def send_dossier(sender, dossier, recipient)
    @sender = sender
    @dossier = dossier
    subject = "#{sender.email} vous a envoyé le dossier nº #{dossier.id}"

    mail(to: recipient.email, subject: subject)
  end

  private

  def vars_mailer(email, args)
    @args = args
    @email = email
  end

  def send_mail(email, args, subject)
    vars_mailer email, args

    mail(to: email, subject: subject)
  end
end
