class AddIndexToDossiersBatchOperationId < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers
  disable_ddl_transaction!
  def up
    add_concurrent_index :dossiers, [:batch_operation_id]
  end
end
