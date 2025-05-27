# frozen_string_literal: true

class AddProceduresNoGender < ActiveRecord::Migration[7.1]
  def change
    add_column :procedures, :no_gender, :boolean, default: false, null: false
  end
end
