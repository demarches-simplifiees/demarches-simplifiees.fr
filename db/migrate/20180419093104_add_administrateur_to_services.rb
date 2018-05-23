class AddAdministrateurToServices < ActiveRecord::Migration[5.2]
  def change
    add_reference :services, :administrateur, foreign_key: true
  end
end
