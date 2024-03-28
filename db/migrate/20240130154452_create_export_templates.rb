class CreateExportTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table :export_templates do |t|
      t.string :name
      t.string :kind
      t.jsonb :content, default: {}
      t.belongs_to :groupe_instructeur, null: false, foreign_key: true

      t.timestamps
    end
  end
end
