class AddMandatoryToTypeDeChamps < ActiveRecord::Migration
  def change
    add_column :types_de_champ, :mandatory, :boolean, default: false
  end
end
