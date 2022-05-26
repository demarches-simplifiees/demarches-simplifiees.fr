class AddConditionalLogicToTypesDeChamp < ActiveRecord::Migration[6.1]
  def change
    add_column :types_de_champ, :conditional_logic_enabled, :boolean, default: false
    add_column :types_de_champ, :conditional_logic_combinator, :string, default: 'AND'

    create_table :type_de_champ_conditions do |t|
      t.references :type_de_champ, null: false, foreign_key: true
      t.bigint :source_type_de_champ_stable_id, null: false
      t.string :operator, null: false
      t.string :value
      t.timestamps
    end
  end
end
