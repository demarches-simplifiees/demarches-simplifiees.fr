class GestionnaireMailerPreview < ActionMailer::Preview
  def last_week_overview
    GestionnaireMailer.last_week_overview(Gestionnaire.first)
  end

  def send_dossier
    GestionnaireMailer.send_dossier(gestionnaire, Dossier.new(id: 10, procedure: procedure), target_gestionnaire)
  end

  def send_login_token
    GestionnaireMailer.send_login_token(gestionnaire, "token")
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

  def target_gestionnaire
    Gestionnaire.new(id: 12, email: 'collegue@administration.gouv.fr')
  end

  def procedure
    Procedure.new(id: 15)
  end
end
