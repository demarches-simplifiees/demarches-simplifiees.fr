# frozen_string_literal: true

class MakePathNonnull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :procedures, :path, false
    add_index :procedures, [:path, :archived_at, :hidden_at], unique: true
  end
end
