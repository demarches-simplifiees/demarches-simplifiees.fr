class AddTestProcedureToProcedurePaths < ActiveRecord::Migration[5.2]
  def change
    add_reference :procedure_paths, :test_procedure
  end
end
