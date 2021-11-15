class AddDeletedAtToCommentaires < ActiveRecord::Migration[6.1]
  def change
    add_column :commentaires, :deleted_at, :datetime
  end
end
