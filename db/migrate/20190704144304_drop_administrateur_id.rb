class DropAdministrateurId < ActiveRecord::Migration[5.2]
  def change
    remove_reference :procedures, :administrateur
  end
end
