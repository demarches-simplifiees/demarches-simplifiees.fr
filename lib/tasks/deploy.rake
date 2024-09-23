# frozen_string_literal: true

namespace :deploy do
  task maintenance_tasks: :environment do
    tasks = MaintenanceTasks::Task
      .load_all
      .filter { _1.respond_to?(:run_on_deploy?) && _1.run_on_deploy? }

    tasks.each do |task|
      Rails.logger.info { "MaintenanceTask run on deploy #{task.name}" }
      MaintenanceTasks::Runner.run(name: task.name)
    end
  end
end
