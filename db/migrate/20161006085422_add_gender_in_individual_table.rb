class AddGenderInIndividualTable < ActiveRecord::Migration[5.2]
  def change
    add_column :individuals, :gender, :string
  end
end
