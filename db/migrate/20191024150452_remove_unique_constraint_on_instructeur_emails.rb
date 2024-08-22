# frozen_string_literal: true

class RemoveUniqueConstraintOnInstructeurEmails < ActiveRecord::Migration[5.2]
  def up
    # Drop the index entirely
    remove_index :instructeurs, :email
    # Add the index again, without the unicity constraint
    add_index :instructeurs, :email
  end

  def down
    remove_index :instructeurs, :email
    add_index :instructeurs, :email, unique: true
  end
end
