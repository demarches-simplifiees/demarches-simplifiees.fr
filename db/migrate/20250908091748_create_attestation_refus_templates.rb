class CreateAttestationRefusTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :attestation_refus_templates do |t|
      t.references :procedure, null: false, foreign_key: true
      t.text :title
      t.text :body
      t.text :footer
      t.boolean :activated, default: false
      t.integer :version, default: 1
      t.string :state, default: 'draft'
      t.json :json_body

      t.timestamps
    end

    add_index :attestation_refus_templates, [:procedure_id, :state], unique: true
  end
end
