class GestionnaireMailerPreview < ActionMailer::Preview
  def last_week_overview
    GestionnaireMailer.last_week_overview(Gestionnaire.last)
  end

  def send_dossier
    GestionnaireMailer.send_dossier(gestionnaire, dossier, target_gestionnaire)
  end

  def send_login_token
    GestionnaireMailer.send_login_token(gestionnaire, "token")
  end

  def invite_gestionnaire
    GestionnaireMailer.invite_gestionnaire(gestionnaire,'aedfa0d0')
  end

  def user_to_gestionnaire
    GestionnaireMailer.user_to_gestionnaire(gestionnaire.email)
  end

  private

  def dossier
    Dossier.new(id: 10, procedure: procedure)
  end

  def procedure
    Procedure.new(id: 1, libelle: 'Démarche pied')
  end

  def gestionnaire
    Gestionnaire.new(id: 10, email: 'Chef.gestionnaire@administration.com')
  end

  def target_gestionnaire
    Gestionnaire.new(id: 12, email: 'target.gestionnaire@administration.com')
  end
end
