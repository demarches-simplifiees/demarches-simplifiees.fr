class DropTablePros < ActiveRecord::Migration
  def change
    drop_table :pros
  end
end
