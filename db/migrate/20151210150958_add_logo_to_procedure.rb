class AddLogoToProcedure < ActiveRecord::Migration
  def change
    add_column :procedures, :logo, :string
  end
end
