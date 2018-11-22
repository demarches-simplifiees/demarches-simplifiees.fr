class RemoveChampIdFromCommentaires < ActiveRecord::Migration[5.2]
  def change
    remove_column :commentaires, :champ_id
  end
end
