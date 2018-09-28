require Rails.root.join("lib", "tasks", "task_helper")

namespace :'2018_08_31_monthly_dossier_expiration_summary' do
  task enable: :environment do
    WarnExpiringDossiersJob.set(cron: "0 0 1 * *").perform_later
  end
end
