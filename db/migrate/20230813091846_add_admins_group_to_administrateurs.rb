class AddAdminsGroupToAdministrateurs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :administrateurs, :admins_group, index: { algorithm: :concurrently }, null: true
  end
end
