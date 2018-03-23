class CreateJoinTableAdministrateursProcedures < ActiveRecord::Migration[5.2]
  def change
    create_join_table :administrateurs, :procedures do |t|
      t.timestamps

      t.index :administrateur_id
      t.index :procedure_id
      t.index [:administrateur_id, :procedure_id], unique: true, name: :index_unique_admin_proc_couple
    end
  end
end
