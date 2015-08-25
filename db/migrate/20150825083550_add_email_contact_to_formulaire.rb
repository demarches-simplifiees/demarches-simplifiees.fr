class AddEmailContactToFormulaire < ActiveRecord::Migration
  def change
    add_column :formulaires, :email_contact, :string
  end
end
