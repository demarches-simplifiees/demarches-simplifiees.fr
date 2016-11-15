class DeleteColumnTestInProcedureTable < ActiveRecord::Migration[5.0]
  def change
    remove_column :procedures, :test
  end
end
