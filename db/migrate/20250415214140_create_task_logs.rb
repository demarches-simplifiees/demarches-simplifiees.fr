# frozen_string_literal: true

class CreateTaskLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :task_logs do |t|
      t.jsonb :data

      t.timestamps
    end
  end
end
