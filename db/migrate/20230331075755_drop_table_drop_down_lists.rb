class DropTableDropDownLists < ActiveRecord::Migration[6.1]
  def up
    drop_table :drop_down_lists
  end
end
