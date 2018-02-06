class AddTypedAndBooleanValueToChamps < ActiveRecord::Migration[5.0]
  def change
    add_column :champs, :typed, :boolean
    add_column :champs, :boolean_value, :boolean
  end
end
