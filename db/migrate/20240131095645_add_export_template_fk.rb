class AddExportTemplateFk < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :exports, :export_templates, validate: false
  end
end
