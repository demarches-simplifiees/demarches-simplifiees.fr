class Cron::FillProcessedAtJob < Cron::CronJob
  self.schedule_expression = 'every day at 6 pm'

  def perform(*args)
    Dossier.where(state: ['accepte', 'refuse', 'sans_suite'], processed_at: nil).find_each do |d|
      d.processed_at = d.traitements.where(state: d.state).last&.processed_at
      d.save if d.processed_at
    end
    AdministrationMailer.processed_at_filling_report.deliver_now
  end
end
