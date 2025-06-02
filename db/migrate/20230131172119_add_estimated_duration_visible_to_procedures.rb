# frozen_string_literal: true

class AddEstimatedDurationVisibleToProcedures < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :estimated_duration_visible, :boolean
    change_column_default :procedures, :estimated_duration_visible, from: nil, to: true
  end
end
