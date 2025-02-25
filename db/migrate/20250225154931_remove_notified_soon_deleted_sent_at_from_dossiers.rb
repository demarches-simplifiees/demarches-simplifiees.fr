# frozen_string_literal: true

class RemoveNotifiedSoonDeletedSentAtFromDossiers < ActiveRecord::Migration[7.0]
  def change
    safety_assured { remove_column :dossiers, :notified_soon_deleted_sent_at, :datetime }
  end
end
