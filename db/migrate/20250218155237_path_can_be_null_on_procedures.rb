# frozen_string_literal: true

class PathCanBeNullOnProcedures < ActiveRecord::Migration[7.0]
  def up
    change_column_null :procedures, :path, true
  end

  def down
    change_column_null :procedures, :path, false
  end
end
