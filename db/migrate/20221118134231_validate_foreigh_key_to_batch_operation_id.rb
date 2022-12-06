class ValidateForeighKeyToBatchOperationId < ActiveRecord::Migration[6.1]
  def change
    validate_foreign_key "dossiers", "batch_operations"
  end
end
