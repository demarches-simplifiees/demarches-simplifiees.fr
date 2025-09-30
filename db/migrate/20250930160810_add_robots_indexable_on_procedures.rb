# frozen_string_literal: true

class AddRobotsIndexableOnProcedures < ActiveRecord::Migration[7.2]
  def change
    add_column :procedures, :robots_indexable, :boolean, default: true, null: false
  end
end
