class RemovePublishedFromProcedures < ActiveRecord::Migration[5.0]
  def change
    remove_column :procedures, :published
  end
end
