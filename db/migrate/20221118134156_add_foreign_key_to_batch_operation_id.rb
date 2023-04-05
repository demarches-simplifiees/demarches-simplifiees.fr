class AddForeignKeyToBatchOperationId < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key "dossiers", "batch_operations", validate: false
  end
end
