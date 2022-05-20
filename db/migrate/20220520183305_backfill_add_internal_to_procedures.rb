class BackfillAddInternalToProcedures < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    Procedure.in_batches do |relation|
      relation.update_all internal: false
      sleep(0.01)
    end
  end
end
