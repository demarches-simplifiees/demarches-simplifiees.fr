class CreateServices < ActiveRecord::Migration[5.2]
  def change
    create_table :services do |t|
      t.string :type_organisme, null: false
      t.string :nom, null: false

      t.timestamps
    end
  end
end
