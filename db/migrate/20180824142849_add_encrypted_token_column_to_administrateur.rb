class AddEncryptedTokenColumnToAdministrateur < ActiveRecord::Migration[5.2]
  def change
    add_column :administrateurs, :encrypted_token, :string
  end
end
