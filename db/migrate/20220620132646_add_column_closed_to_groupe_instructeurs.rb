class AddColumnClosedToGroupeInstructeurs < ActiveRecord::Migration[6.1]
  def change
    add_column :groupe_instructeurs, :closed, :boolean, default: false
  end
end
