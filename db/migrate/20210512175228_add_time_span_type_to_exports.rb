# frozen_string_literal: true

class AddTimeSpanTypeToExports < ActiveRecord::Migration[6.1]
  def change
    add_column :exports, :time_span_type, :string, default: 'everything', null: false
    remove_index :exports, [:format, :key]
    add_index :exports, [:format, :time_span_type, :key], unique: true
  end
end
