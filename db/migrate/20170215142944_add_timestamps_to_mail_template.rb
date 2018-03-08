class AddTimestampsToMailTemplate < ActiveRecord::Migration[5.2]
  def change
    add_column :mail_templates, :created_at, :datetime
    add_column :mail_templates, :updated_at, :datetime
  end
end
