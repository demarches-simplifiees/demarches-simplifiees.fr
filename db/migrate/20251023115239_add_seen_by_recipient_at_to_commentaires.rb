# frozen_string_literal: true

class AddSeenByRecipientAtToCommentaires < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    return if column_exists?(:commentaires, :seen_by_recipient_at)
    add_column :commentaires, :seen_by_recipient_at, :datetime
  end

  def down
    remove_column :commentaires, :seen_by_recipient_at if column_exists?(:commentaires, :seen_by_recipient_at)
  end
end
