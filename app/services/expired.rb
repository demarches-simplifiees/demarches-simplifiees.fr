module Expired
  def self.schedule_at(caller)
    case caller.name
    when 'Cron::ExpiredPrefilledDossiersDeletionJob'
      "every day at 3 am"
    when 'Cron::ExpiredDossiersTermineDeletionJob'
      "every day at 7 am"
    when 'Cron::ExpiredDossiersBrouillonDeletionJob'
      "every day at 10 pm"
    when 'Cron::ExpiredUsersDeletionJob'
      "every day at 11 pm"
    when 'Cron::ExpiredDossiersEnConstructionDeletionJob'
      "every day at 3 pm"
    else
      raise 'please, check the schedule to avoid too much email at the same time'
    end
  end
end