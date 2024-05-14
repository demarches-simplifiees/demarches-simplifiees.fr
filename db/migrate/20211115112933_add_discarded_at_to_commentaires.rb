# frozen_string_literal: true

class AddDiscardedAtToCommentaires < ActiveRecord::Migration[6.1]
  def change
    add_column :commentaires, :discarded_at, :datetime
    # add_index :commentaires, :discarded_at
  end
end
