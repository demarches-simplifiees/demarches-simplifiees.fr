class AddGenderInIndividualTable < ActiveRecord::Migration
  def change
    add_column :individuals, :gender, :string
  end
end
