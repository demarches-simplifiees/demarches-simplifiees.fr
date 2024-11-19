# frozen_string_literal: true

class AddNotifiedSoonDeletedSentAtToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :notified_soon_deleted_sent_at, :datetime
  end
end
