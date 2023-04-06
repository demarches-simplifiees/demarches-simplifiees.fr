class AddBatchOperationIdToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :batch_operation_id, :bigint
  end
end
