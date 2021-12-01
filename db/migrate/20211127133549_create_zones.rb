class CreateZones < ActiveRecord::Migration[6.1]
  def change
    create_table :zones do |t|
      t.string :acronym
      t.string :label

      t.timestamps
    end
  end
end
