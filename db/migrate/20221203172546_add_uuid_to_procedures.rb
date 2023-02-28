class AddUUIDToProcedures < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :uuid, :uuid, null: true, unique: true, default: -> { "gen_random_uuid()" }
  end
end
