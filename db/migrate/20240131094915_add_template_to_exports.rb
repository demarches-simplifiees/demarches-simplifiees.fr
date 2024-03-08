class AddTemplateToExports < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_reference :exports, :export_template, null: true, index: {algorithm: :concurrently}
  end
end
