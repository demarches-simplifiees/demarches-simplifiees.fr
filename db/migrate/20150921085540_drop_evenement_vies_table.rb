class DropEvenementViesTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :evenement_vies
  end
end
