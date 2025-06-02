# frozen_string_literal: true

class RemoveUniqueConstraintOnAdministrateurEmails < ActiveRecord::Migration[5.2]
  def up
    # Drop the index entirely
    remove_index :administrateurs, :email
    # Add the index again, without the unicity constraint
    add_index :administrateurs, :email
  end

  def down
    remove_index :administrateurs, :email
    add_index :administrateurs, :email, unique: true
  end
end
