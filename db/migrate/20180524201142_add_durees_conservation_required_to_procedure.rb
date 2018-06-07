class AddDureesConservationRequiredToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :durees_conservation_required, :boolean, default: true
  end
end
