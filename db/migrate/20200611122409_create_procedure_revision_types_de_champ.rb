class CreateProcedureRevisionTypesDeChamp < ActiveRecord::Migration[5.2]
  def change
    create_table :procedure_revision_types_de_champ do |t|
      t.references :procedure_revision, foreign_key: true, null: false, index: { name: 'index_revision_types_de_champ_on_revision' }
      t.references :type_de_champ, foreign_key: true, null: false, index: { name: 'index_revision_types_de_champ_on_type_de_champ' }

      t.integer :position, null: false

      t.timestamps
    end
  end
end
