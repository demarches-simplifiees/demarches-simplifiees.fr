class DropCerfas < ActiveRecord::Migration[5.2]
  def change
    drop_table :cerfas
  end
end
