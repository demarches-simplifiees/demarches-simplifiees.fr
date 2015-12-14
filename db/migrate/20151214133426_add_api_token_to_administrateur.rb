class AddAPITokenToAdministrateur < ActiveRecord::Migration
  def change
    add_column :administrateurs, :api_token, :string
  end
end
