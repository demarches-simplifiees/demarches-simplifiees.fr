class AddAPITokenToAdministrateur < ActiveRecord::Migration[5.2]
  def change
    add_column :administrateurs, :api_token, :string
  end
end
