class AddAasmStateToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :aasm_state, :string, index: true, default: :brouillon
  end
end
