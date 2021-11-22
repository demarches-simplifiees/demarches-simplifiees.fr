class AddForeignKeyToAvisDossierId < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :avis, :dossiers
  end
end
