class CreateCommentaires < ActiveRecord::Migration
  def change
    create_table :commentaires do |t|
      t.string :email
      t.date :created_at
      t.string :body
      t.references :dossier, index: true

      t.timestamps null: false
    end
    add_foreign_key :commentaires, :dossiers
  end
end
