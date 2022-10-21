class AddTagsToProcedures < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!
  def change
    add_column :procedures, :tags, :text, array: true, default: []
    add_index :procedures, :tags, using: 'gin', algorithm: :concurrently
  end
end
