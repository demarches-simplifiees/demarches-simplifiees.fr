class AddChampIdToCommentaires < ActiveRecord::Migration
  def change
    change_table :commentaires do |t|
      t.references :champ, null: true, index: true
    end
  end
end
