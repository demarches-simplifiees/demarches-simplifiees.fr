class InstructeursRemoveEmail < ActiveRecord::Migration[5.2]
  def change
    remove_column :instructeurs, :email
  end
end
