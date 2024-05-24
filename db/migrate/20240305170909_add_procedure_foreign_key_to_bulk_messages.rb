class AddProcedureForeignKeyToBulkMessages < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :bulk_messages, :procedures
  end
end
