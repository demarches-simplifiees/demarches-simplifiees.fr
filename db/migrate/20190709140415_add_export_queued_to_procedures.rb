# frozen_string_literal: true

class AddExportQueuedToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :csv_export_queued, :boolean
    add_column :procedures, :xlsx_export_queued, :boolean
    add_column :procedures, :ods_export_queued, :boolean
  end
end
