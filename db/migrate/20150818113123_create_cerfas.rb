class CreateCerfas < ActiveRecord::Migration
  def change
    create_table :cerfas do |t|
      t.string :content
      t.references :dossier, index: true
    end
    add_foreign_key :cerfas, :dossiers
  end
end
