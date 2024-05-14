# frozen_string_literal: true

class AddRevokedAtToExpertsProcedures < ActiveRecord::Migration[6.1]
  def change
    add_column :experts_procedures, :revoked_at, :datetime
  end
end
