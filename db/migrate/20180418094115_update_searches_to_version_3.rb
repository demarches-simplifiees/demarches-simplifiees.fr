class UpdateSearchesToVersion3 < ActiveRecord::Migration[5.2]
  def up
    replace_view :searches, version: 3
  end

  def down
    replace_view :searches, version: 2
  end
end
