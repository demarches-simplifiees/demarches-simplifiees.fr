class UpdateSearchesToVersion4 < ActiveRecord::Migration[5.2]
  def up
    replace_view :searches, version: 4
  end

  def down
    replace_view :searches, version: 3
  end
end
