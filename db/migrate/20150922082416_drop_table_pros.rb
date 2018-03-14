class DropTablePros < ActiveRecord::Migration[5.2]
  def change
    drop_table :pros
  end
end
