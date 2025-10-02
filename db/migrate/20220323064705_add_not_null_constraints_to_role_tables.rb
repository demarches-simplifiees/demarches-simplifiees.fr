# frozen_string_literal: true

class AddNotNullConstraintsToRoleTables < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers

  def change
    # (We ignore strong_migrations safety warnings, because those tables are relatively small, and the null check
    # will be very fast.)
    safety_assured do
      change_column_null :administrateurs, :user_id, false
      change_column_null :instructeurs, :user_id, false
      change_column_null :experts, :user_id, false
    end
  end
end
