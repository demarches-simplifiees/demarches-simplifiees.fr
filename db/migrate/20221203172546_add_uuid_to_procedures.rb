class AddUuidToProcedures < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :uuid, :uuid, null: true, unique: true
  end
end
