# frozen_string_literal: true

class AddFilteredAndSortedColumnToExportsTable < ActiveRecord::Migration[7.0]
  def change
    add_column :exports, :filtered_columns, :jsonb, array: true, default: [], null: false
    add_column :exports, :sorted_column, :jsonb
  end
end
