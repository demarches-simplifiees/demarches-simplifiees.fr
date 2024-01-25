class AddContextToExports < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    safety_assured do
      add_reference :exports, :instructeur, foreign_key: true, null: true, default: nil, index: { algorithm: :concurrently }
    end

    add_column :exports, :dossiers_count, :integer, null: true, default: nil
  end
end
