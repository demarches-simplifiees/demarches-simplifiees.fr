# frozen_string_literal: true

class AddValidRuleAndUnicRuleToGroupeInstructeurs < ActiveRecord::Migration[7.2]
  def change
    add_column :groupe_instructeurs, :valid_rule, :boolean, default: false, null: false
    add_column :groupe_instructeurs, :unic_rule, :boolean, default: false, null: false
  end
end
