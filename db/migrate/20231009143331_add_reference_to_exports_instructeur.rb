class AddReferenceToExportsInstructeur < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    unless column_exists?(:exports, :instructeur_id)
      safety_assured do
        add_reference :exports, :instructeur, foreign_key: true, null: true, default: nil, index: { algorithm: :concurrently }
      end
    end
  end
end
