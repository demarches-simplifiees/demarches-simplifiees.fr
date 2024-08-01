# frozen_string_literal: true

class AddTermineCloseToExpirationToDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :termine_close_to_expiration_notice_sent_at, :datetime
  end
end
