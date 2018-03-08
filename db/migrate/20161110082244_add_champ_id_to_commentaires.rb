class AddChampIdToCommentaires < ActiveRecord::Migration[5.2]
  def change
    change_table :commentaires do |t|
      t.references :champ, null: true, index: true
    end
  end
end
