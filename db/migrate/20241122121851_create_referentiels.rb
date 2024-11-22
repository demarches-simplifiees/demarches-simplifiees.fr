class CreateReferentiels < ActiveRecord::Migration[7.0]
  def change
    create_table :referentiels do |t|
      t.bigint :type_de_champ_stable_id, null: false
      t.bigint :procedure_id, null: false
      t.string :name, null: false
      t.timestamps
    end
  end
end
