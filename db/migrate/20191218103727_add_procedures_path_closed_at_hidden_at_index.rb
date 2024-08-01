# frozen_string_literal: true

class AddProceduresPathClosedAtHiddenAtIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :procedures, [:path, :closed_at, :hidden_at], unique: true
    remove_index :procedures, [:path, :archived_at, :hidden_at]
  end
end
