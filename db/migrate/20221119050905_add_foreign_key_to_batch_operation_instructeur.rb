class AddForeignKeyToBatchOperationInstructeur < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key "batch_operations", "instructeurs", validate: false
  end
end
