class AddEstimatedDurationVisibleToProcedures < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :estimated_duration_visible, :boolean, default: true, null: false
  end
end
