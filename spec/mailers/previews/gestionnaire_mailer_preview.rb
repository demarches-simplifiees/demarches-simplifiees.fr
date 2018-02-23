class GestionnaireMailerPreview < ActionMailer::Preview
  def last_week_overview
    gestionnaire = Gestionnaire.first
    GestionnaireMailer.last_week_overview(gestionnaire, gestionnaire.last_week_overview)
  end

  def send_dossier
    GestionnaireMailer.send_dossier(Gestionnaire.first, Dossier.first, Gestionnaire.last)
  end
end
