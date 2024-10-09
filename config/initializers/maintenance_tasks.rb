# frozen_string_literal: true

Rails.application.config.after_initialize do
  if defined?(Rails::Generators)
    require "generators/maintenance_tasks/task_generator"

    class MaintenanceTasks::TaskGenerator
      alias_method :original_assign_names!, :assign_names!
      source_paths << Rails.root.join("lib/templates/maintenance_tasks")

      private

      # Prefix the task name with a date so the tasks are better sorted.
      def assign_names!(name)
        timestamped_name = "T#{Date.current.strftime("%Y%m%d")}#{name}"
        original_assign_names!(timestamped_name)
      end
    end
  end
end
