class AddColumnsToService < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :organisme, :string
    add_column :services, :email, :string
    add_column :services, :telephone, :string
    add_column :services, :horaires, :text
    add_column :services, :adresse, :text
  end
end
