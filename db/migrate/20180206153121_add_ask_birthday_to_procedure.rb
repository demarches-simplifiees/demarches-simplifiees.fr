class AddAskBirthdayToProcedure < ActiveRecord::Migration[5.0]
  def change
    add_column :procedures, :ask_birthday, :boolean, default: false, null: false
  end
end
