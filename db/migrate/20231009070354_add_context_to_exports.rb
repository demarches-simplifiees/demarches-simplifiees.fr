class AddContextToExports < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :exports, :dossiers_count, :integer, null: true, default: nil
  end
end
