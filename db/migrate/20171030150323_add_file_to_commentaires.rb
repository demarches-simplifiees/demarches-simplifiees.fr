class AddFileToCommentaires < ActiveRecord::Migration[5.2]
  def change
    add_column :commentaires, :file, :string
  end
end
