class AddTestStartedAtToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :test_started_at, :datetime, index: true
  end
end
