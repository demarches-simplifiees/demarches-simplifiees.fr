# frozen_string_literal: true

class AddSharedToExportTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :export_templates, :shared, :boolean, default: false, null: false
  end
end
