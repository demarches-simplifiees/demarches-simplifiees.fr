class AddTwoFieldsForDescriptionToProcedure < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :description_what, :string
    add_column :procedures, :description_for_who, :string
  end
end
