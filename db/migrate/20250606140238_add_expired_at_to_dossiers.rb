class AddExpiredAtToDossiers < ActiveRecord::Migration[7.1]
  def change
    add_column :dossiers, :expired_at, :datetime
  end
end
