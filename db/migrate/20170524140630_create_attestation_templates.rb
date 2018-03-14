class CreateAttestationTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :attestation_templates do |t|
      t.text :title
      t.text :body
      t.text :footer
      t.string :logo
      t.string :signature
      t.boolean :activated

      t.timestamps

      t.references :procedure, index: { unique: true }, foreign_key: true
    end
  end
end
