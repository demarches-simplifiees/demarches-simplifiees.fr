class AddLockableToDevise < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :unlock_token, :string
    add_column :users, :locked_at, :datetime
    add_index :users, :unlock_token, unique: true

    add_column :gestionnaires, :failed_attempts, :integer, default: 0, null: false
    add_column :gestionnaires, :unlock_token, :string
    add_column :gestionnaires, :locked_at, :datetime
    add_index :gestionnaires, :unlock_token, unique: true

    add_column :administrateurs, :failed_attempts, :integer, default: 0, null: false
    add_column :administrateurs, :unlock_token, :string
    add_column :administrateurs, :locked_at, :datetime
    add_index :administrateurs, :unlock_token, unique: true

    add_column :administrations, :failed_attempts, :integer, default: 0, null: false
    add_column :administrations, :unlock_token, :string
    add_column :administrations, :locked_at, :datetime
    add_index :administrations, :unlock_token, unique: true
  end
end
