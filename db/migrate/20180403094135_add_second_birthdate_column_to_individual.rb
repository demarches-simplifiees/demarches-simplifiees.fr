class AddSecondBirthdateColumnToIndividual < ActiveRecord::Migration[5.2]
  def change
    add_column :individuals, :second_birthdate, :date
  end
end
