# frozen_string_literal: true

class AddNearDeletionNoticeSendToDossier < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :brouillon_close_to_expiration_notice_sent_at, :datetime
  end
end
