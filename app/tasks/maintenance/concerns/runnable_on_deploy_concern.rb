# frozen_string_literal: true

module Maintenance
  module RunnableOnDeployConcern
    extend ActiveSupport::Concern

    class_methods do
      def run_on_first_deploy
        @run_on_first_deploy = true
      end

      def run_on_deploy?
        return false unless @run_on_first_deploy

        task = MaintenanceTasks::TaskDataShow.new(name)

        return false if task.completed_runs.not_errored.any?
        return false if task.active_runs.any?

        true
      end
    end
  end
end
