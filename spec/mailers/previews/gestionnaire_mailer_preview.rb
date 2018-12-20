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

  def invite_gestionnaire
    GestionnaireMailer.invite_gestionnaire(gestionnaire, 'aedfa0d0')
  end

  def user_to_gestionnaire
    GestionnaireMailer.user_to_gestionnaire(gestionnaire.email)
  end

  private

  def gestionnaire
    Gestionnaire.new(id: 10, email: 'instructeur@administration.gouv.fr')
  end
end
