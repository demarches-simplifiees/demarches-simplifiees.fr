class CreateContactForms < ActiveRecord::Migration[7.0]
  def change
    create_table :contact_forms do |t|
      t.string :email
      t.string :subject, null: false
      t.text :text, null: false
      t.string :question_type, null: false
      t.references :user, null: true, foreign_key: true
      t.bigint :dossier_id # not a reference (dossier may not exist)
      t.string :phone
      t.string :tags, array: true, default: []
      t.boolean :for_admin, default: false, null: false

      t.timestamps
    end
  end
end
