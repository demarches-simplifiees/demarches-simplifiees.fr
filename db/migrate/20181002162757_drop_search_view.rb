class DropSearchView < ActiveRecord::Migration[5.2]
  def change
    drop_view :searches, revert_to_version: 4
  end
end
