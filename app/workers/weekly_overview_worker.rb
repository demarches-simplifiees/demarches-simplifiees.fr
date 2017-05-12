class WeeklyOverviewWorker
  include Sidekiq::Worker

  def perform(*args)
    Gestionnaire.all
      .map { |gestionnaire| [gestionnaire, gestionnaire.last_week_overview] }
      .reject { |_, overview| overview.nil? }
      .each { |gestionnaire, overview| GestionnaireMailer.last_week_overview(gestionnaire, overview).deliver_now }
  end
end
