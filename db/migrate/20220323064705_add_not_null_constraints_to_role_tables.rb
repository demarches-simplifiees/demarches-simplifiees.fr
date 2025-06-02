# frozen_string_literal: true

class AddNotNullConstraintsToRoleTables < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers

  def change
    # If this migration fails, that means you need to run the matching data migration task first.
    # Please run:
    #   bin/rake after_party:copy_user_association_to_user_related_models
    #   bin/rake after_party:delete_roles_without_users
    #
    # (We ignore strong_migrations safety warnings, because those tables are relatively small, and the null check
    # will be very fast.)
    safety_assured do
      change_column_null :administrateurs, :user_id, false
      change_column_null :instructeurs, :user_id, false
      change_column_null :experts, :user_id, false
    end
  end
end
