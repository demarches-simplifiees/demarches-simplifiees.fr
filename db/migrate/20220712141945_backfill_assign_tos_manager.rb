class BackfillAssignTosManager < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    AssignTo.in_batches do |relation|
      relation.update_all manager: false
      sleep(0.01)
    end
  end
end
