class CreateTagsProcedures < ActiveRecord::Migration[6.1]
  def change
    create_table :tags_procedures do |t|
      t.references :procedure, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end
  end
end
