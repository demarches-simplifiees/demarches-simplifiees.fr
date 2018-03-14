class AddAskBirthdayToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :ask_birthday, :boolean, default: false, null: false
  end
end
