class DropMailTemplatesTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :mail_templates
  end
end
