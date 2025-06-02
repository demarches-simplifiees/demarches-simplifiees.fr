# frozen_string_literal: true

class AddForeignKeysToRoleTables < ActiveRecord::Migration[6.1]
  def change
    # Add foreign keys constraints to role tables.
    #
    # (We don't validate foreign keys right now, to avoid blocking writes to these tables for too long.)
    add_foreign_key :administrateurs, :users, validate: false
    add_foreign_key :instructeurs, :users, validate: false
    add_foreign_key :experts, :users, validate: false
  end
end
