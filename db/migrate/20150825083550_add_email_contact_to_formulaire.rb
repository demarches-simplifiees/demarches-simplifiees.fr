class AddEmailContactToFormulaire < ActiveRecord::Migration[5.2]
  def change
    add_column :formulaires, :email_contact, :string
  end
end
