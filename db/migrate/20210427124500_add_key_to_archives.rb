# frozen_string_literal: true

class AddKeyToArchives < ActiveRecord::Migration[6.1]
  def change
    add_column :archives, :key, :text, null: false
    add_index :archives, [:key, :time_span_type, :month], unique: true
  end
end
