class GestionnaireMailerPreview < ActionMailer::Preview
  def last_week_overview
    gestionnaire = Gestionnaire.first
    GestionnaireMailer.last_week_overview(gestionnaire)
  end

  def send_dossier
    GestionnaireMailer.send_dossier(Gestionnaire.first, Dossier.first, Gestionnaire.last)
  end

  def send_login_token
    GestionnaireMailer.send_login_token(Gestionnaire.first, "token")
  end
end
