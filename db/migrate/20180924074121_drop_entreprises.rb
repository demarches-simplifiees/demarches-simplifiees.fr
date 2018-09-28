class DropEntreprises < ActiveRecord::Migration[5.2]
  def change
    drop_table :entreprises
  end
end
