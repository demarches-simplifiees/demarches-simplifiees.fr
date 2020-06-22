class AdministrateurActivateBeforeExpirationJob < CronJob
  self.schedule_expression = "every day at 8 am"

  def perform(*args)
    Administrateur
      .includes(:user)
      .inactive
      .where(created_at: 3.days.ago.all_day)
      .each { |a| a.user.remind_invitation! }
  end
end
