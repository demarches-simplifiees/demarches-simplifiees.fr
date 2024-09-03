# frozen_string_literal: true

class AddDeletedUserEmailNeverSendToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :deleted_user_email_never_send, :string
  end
end
