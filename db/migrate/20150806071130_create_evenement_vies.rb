class CreateEvenementVies < ActiveRecord::Migration[5.2]
  def change
    create_table :evenement_vies do |t|
      t.string :nom

      t.timestamps null: false
    end
  end
end
