# frozen_string_literal: true

# This migration comes from maintenance_tasks (originally 20201211151756)
class CreateMaintenanceTasksRuns < ActiveRecord::Migration[6.0]
  def change
    create_table(:maintenance_tasks_runs) do |t|
      t.string(:task_name, null: false)
      t.datetime(:started_at)
      t.datetime(:ended_at)
      t.float(:time_running, default: 0.0, null: false)
      t.bigint(:tick_count, default: 0, null: false)
      t.bigint(:tick_total)
      t.string(:job_id)
      t.string(:cursor)
      t.string(:status, default: :enqueued, null: false)
      t.string(:error_class)
      t.string(:error_message)
      t.text(:backtrace)
      t.timestamps
      t.index([:task_name, :status, :created_at], order: { created_at: :desc }, name: :index_maintenance_tasks_runs)
    end
  end
end
