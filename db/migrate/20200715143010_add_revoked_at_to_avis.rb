# frozen_string_literal: true

class AddRevokedAtToAvis < ActiveRecord::Migration[6.0]
  def change
    add_column :avis, :revoked_at, :datetime
  end
end
