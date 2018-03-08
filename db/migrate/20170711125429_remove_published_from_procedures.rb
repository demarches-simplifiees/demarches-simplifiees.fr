class RemovePublishedFromProcedures < ActiveRecord::Migration[5.2]
  def change
    remove_column :procedures, :published
  end
end
