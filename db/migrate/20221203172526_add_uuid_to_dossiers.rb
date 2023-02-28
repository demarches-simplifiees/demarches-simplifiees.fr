class AddUUIDToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :uuid, :uuid, null: true, unique: true, default: -> { "gen_random_uuid()" }
  end
end
