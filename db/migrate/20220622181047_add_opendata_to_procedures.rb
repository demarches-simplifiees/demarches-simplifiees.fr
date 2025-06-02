# frozen_string_literal: true

class AddOpendataToProcedures < ActiveRecord::Migration[6.1]
  def up
    add_column :procedures, :opendata, :boolean
    change_column_default :procedures, :opendata, true
  end

  def down
    remove_column :procedures, :opendata
  end
end
