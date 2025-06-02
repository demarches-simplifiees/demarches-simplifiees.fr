# frozen_string_literal: true

class AddCacheKeyToExports < ActiveRecord::Migration[6.1]
  def change
    add_column :exports, :key, :text
    add_index :exports, [:format, :key], unique: true
  end
end
