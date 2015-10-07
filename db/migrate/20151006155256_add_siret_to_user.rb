class AddSiretToUser < ActiveRecord::Migration
  def change
    add_column :users, :siret, :string
  end
end
