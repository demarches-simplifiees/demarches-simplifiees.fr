class AddProcedurePresentationAndStateToExports < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_reference :exports, :procedure_presentation, null: true, index: { algorithm: :concurrently }
    add_column :exports, :statut, :string, default: 'tous'
    remove_index :exports, [:format, :time_span_type, :key]
    add_index :exports, [:format, :time_span_type, :statut, :key], unique: true, algorithm: :concurrently
  end
end
