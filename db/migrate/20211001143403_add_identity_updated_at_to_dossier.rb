# frozen_string_literal: true

class AddIdentityUpdatedAtToDossier < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :identity_updated_at, :datetime
  end
end
