class AddReferenceToExportsInstructeur < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # Foreign key is added in a later migration
    add_reference :exports, :instructeur, null: true, default: nil, index: { algorithm: :concurrently }, foreign_key: false
  end
end
