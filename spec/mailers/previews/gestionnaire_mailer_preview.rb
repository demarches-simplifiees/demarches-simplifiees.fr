class GestionnaireMailerPreview < ActionMailer::Preview
  def last_week_overview
    gestionnaire = Gestionnaire.first
    GestionnaireMailer.last_week_overview(gestionnaire, gestionnaire.last_week_overview)
  end
end
