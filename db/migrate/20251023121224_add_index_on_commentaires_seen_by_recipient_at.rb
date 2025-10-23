# frozen_string_literal: true

class AddIndexOnCommentairesSeenByRecipientAt < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :commentaires, :seen_by_recipient_at,
              name: :index_commentaires_on_seen_by_recipient_at,
              algorithm: :concurrently unless index_exists?(:commentaires, :seen_by_recipient_at, name: :index_commentaires_on_seen_by_recipient_at)
  end
end
