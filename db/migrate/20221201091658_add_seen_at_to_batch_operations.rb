class AddSeenAtToBatchOperations < ActiveRecord::Migration[6.1]
  def change
    add_column :batch_operations, :seen_at, :datetime
  end
end
