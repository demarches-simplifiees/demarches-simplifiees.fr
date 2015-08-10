class CreateDossiers < ActiveRecord::Migration
  def change
    create_table :dossiers do |t|
      t.string :description
    end
  end
end
