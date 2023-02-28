class AddUUIDToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :uuid, :uuid, null: true, unique: true, default: -> { "gen_random_uuid()" }
  end
end
