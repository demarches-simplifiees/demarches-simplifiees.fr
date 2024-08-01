# frozen_string_literal: true

class DropBulkMessagesGroupeInstructeurs < ActiveRecord::Migration[7.0]
  def change
    drop_table :bulk_messages_groupe_instructeurs
  end
end
