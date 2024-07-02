class RemoveChampsForeignKey < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :champs, column: :parent_id
  end
end
