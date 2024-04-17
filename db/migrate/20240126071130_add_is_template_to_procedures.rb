class AddIsTemplateToProcedures < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :template, :boolean, default: false, null: false
  end
end
