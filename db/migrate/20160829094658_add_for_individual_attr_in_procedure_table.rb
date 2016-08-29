class AddForIndividualAttrInProcedureTable < ActiveRecord::Migration
  def change
    add_column :procedures, :for_individual, :boolean, default: false
  end
end
