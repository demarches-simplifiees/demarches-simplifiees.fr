# frozen_string_literal: true

class AddColumnClosedToGroupeInstructeurs < ActiveRecord::Migration[6.1]
  def change
    add_column :groupe_instructeurs, :closed, :boolean
    change_column_default :groupe_instructeurs, :closed, false
  end
end
