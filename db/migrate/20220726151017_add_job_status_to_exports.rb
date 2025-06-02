# frozen_string_literal: true

class AddJobStatusToExports < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_column :exports, :job_status, :string, null: false, default: "pending"
    end
  end
end
