class AddRowIdToChamps < ActiveRecord::Migration[6.1]
  def change
    add_column :champs, :row_id, :string
  end
end
