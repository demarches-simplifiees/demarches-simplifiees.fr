# frozen_string_literal: true

class DropTableDropDownLists < ActiveRecord::Migration[6.1]
  def up
    drop_table :drop_down_lists if table_exists?(:drop_down_lists)
  end
end
