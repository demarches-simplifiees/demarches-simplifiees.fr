require Rails.root.join("lib", "tasks", "task_helper")

namespace :'2019_09_16_daily_db_space_usage_update' do
  task enable: :environment do
    # every day, 1am
    PgHero.capture_space_stats.set(cron: "0 1 * * *").perform_later
  end
end
