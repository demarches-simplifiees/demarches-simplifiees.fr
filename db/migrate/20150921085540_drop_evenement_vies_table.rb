class DropEvenementViesTable < ActiveRecord::Migration
  def change
    drop_table :evenement_vies
  end
end
