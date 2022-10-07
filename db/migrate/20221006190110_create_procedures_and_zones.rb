class CreateProceduresAndZones < ActiveRecord::Migration[6.1]
  def change
    create_table :procedures_zones, id: false do |t|
      t.belongs_to :procedure
      t.belongs_to :zone

      t.timestamps
    end
  end
end
