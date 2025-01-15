# frozen_string_literal: true

require "generators/maintenance_tasks/task_generator"

module MaintenanceTasks
  module Generators
    class TaskGenerator < MaintenanceTasks::TaskGenerator
      # Customizes the task template while keeping the original spec template
      def self.source_paths
        @source_paths ||= begin
          custom_path = Rails.root.join("lib/templates/maintenance_tasks")
          gem_path = Gem::Specification.find_by_name("maintenance_tasks").gem_dir
          gem_templates = File.join(gem_path, "lib/generators/maintenance_tasks/templates")

          [custom_path, gem_templates]
        end
      end

      private

      # Prefix the task name with a date so the tasks are better sorted.
      def assign_names!(name)
        timestamped_name = "T#{Date.current.strftime("%Y%m%d")}#{name}"
        super(timestamped_name)
      end
    end
  end
end
