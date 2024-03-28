class ValidateExportTemplateFk < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :exports, :export_templates
  end
end
