# frozen_string_literal: true

class AddInstructeurForeignKeyToExports < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # Foreign keys were already added on developer machines, but timeouted in production.
    if !foreign_key_exists?(:exports, :instructeurs)
      add_foreign_key :exports, :instructeurs, validate: false
      validate_foreign_key :exports, :instructeurs
    end
  end

  def down
    if foreign_key_exists?(:exports, :instructeurs)
      remove_foreign_key :exports, :instructeurs
    end
  end
end
