# frozen_string_literal: true

class AddEnConstructionCloseToExpirationToDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :en_construction_close_to_expiration_notice_sent_at, :datetime
  end
end
