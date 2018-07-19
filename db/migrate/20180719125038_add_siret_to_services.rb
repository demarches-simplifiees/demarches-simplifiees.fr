class AddSiretToServices < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :siret, :string
  end
end
