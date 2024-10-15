# frozen_string_literal: true

class AddColumnsToExportTemplate < ActiveRecord::Migration[7.0]
  def change
    add_column :export_templates, :exported_columns, :jsonb, array: true, default: [], null: false
  end
end
