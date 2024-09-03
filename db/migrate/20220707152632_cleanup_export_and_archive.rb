# frozen_string_literal: true

class CleanupExportAndArchive < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      rename_column :archives, :status, :job_status
    end
  end
end
