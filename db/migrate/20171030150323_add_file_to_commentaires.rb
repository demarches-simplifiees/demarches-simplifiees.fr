class AddFileToCommentaires < ActiveRecord::Migration[5.0]
  def change
    add_column :commentaires, :file, :string
  end
end
