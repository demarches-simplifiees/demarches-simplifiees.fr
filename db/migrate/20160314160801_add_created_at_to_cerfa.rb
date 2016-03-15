class AddCreatedAtToCerfa < ActiveRecord::Migration
  def change
    add_column :cerfas, :created_at, :datetime
  end
end
