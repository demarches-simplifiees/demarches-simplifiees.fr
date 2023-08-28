class AddChorusColumnToProcedure < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :chorus, :jsonb, default: {}, null: false
  end
end
