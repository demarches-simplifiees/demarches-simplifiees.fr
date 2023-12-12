class CreateAgentConnectInformations < ActiveRecord::Migration[7.0]
  def change
    create_table :agent_connect_informations do |t|
      t.references :instructeur, null: false, foreign_key: true
      t.string :given_name, null: false
      t.string :usual_name, null: false
      t.string :email, null: false
      t.string :sub, null: false
      t.string :siret
      t.string :organizational_unit
      t.string :belonging_population
      t.string :phone

      t.timestamps
    end
  end
end
