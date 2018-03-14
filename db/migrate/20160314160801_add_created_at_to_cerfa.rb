class AddCreatedAtToCerfa < ActiveRecord::Migration[5.2]
  def change
    add_column :cerfas, :created_at, :datetime
  end
end
