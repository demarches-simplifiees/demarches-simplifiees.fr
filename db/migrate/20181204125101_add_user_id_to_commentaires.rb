class AddUserIdToCommentaires < ActiveRecord::Migration[5.2]
  def change
    add_column :commentaires, :user_id, :bigint
    add_column :commentaires, :gestionnaire_id, :bigint

    add_index :commentaires, :user_id
    add_index :commentaires, :gestionnaire_id
  end
end
