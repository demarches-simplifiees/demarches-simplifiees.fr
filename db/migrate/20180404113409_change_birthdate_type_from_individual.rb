class ChangeBirthdateTypeFromIndividual < ActiveRecord::Migration[5.2]
  def up
    remove_column :individuals, :birthdate, :string
    rename_column :individuals, :second_birthdate, :birthdate
  end
end
