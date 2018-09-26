class DeleteAPITokenColumnFromAdministrateur < ActiveRecord::Migration[5.2]
  def change
    remove_column :administrateurs, :api_token, :string
  end
end
