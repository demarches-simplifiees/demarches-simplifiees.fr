class AddForIndividualAttrInProcedureTable < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :for_individual, :boolean, default: false
  end
end
