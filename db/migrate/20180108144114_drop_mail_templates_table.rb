class DropMailTemplatesTable < ActiveRecord::Migration[5.0]
  def change
    drop_table :mail_templates
  end
end
