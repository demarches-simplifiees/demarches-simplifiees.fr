class AddSiretToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :siret, :string
  end
end
