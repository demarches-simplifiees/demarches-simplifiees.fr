class CreateDossiers < ActiveRecord::Migration[5.2]
  def change
    create_table :dossiers do |t|
      t.string :description
    end
  end
end
