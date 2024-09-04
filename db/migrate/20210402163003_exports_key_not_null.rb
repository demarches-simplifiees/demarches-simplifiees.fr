# frozen_string_literal: true

class ExportsKeyNotNull < ActiveRecord::Migration[6.1]
  def change
    change_column_null :exports, :key, false
  end
end
