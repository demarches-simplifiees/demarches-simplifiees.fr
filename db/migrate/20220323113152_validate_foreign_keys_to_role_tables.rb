# frozen_string_literal: true

class ValidateForeignKeysToRoleTables < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    # Now that the foreign keys are added, we can validate them safely without blocking writes.
    validate_foreign_key :administrateurs, :users
    validate_foreign_key :instructeurs, :users
    validate_foreign_key :experts, :users
  end
end
