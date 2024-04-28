# frozen_string_literal: true

class AddUniqueIndexToBulkMessagesGroupeInstructeurs < ActiveRecord::Migration[6.1]
  def change
    add_index :bulk_messages_groupe_instructeurs, [:bulk_message_id, :groupe_instructeur_id], unique: true, name: :index_bulk_msg_gi_on_bulk_msg_id_and_gi_id
  end
end
