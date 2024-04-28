# frozen_string_literal: true

class AddAllowExpertMessagingToProcedures < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :allow_expert_messaging, :boolean, default: true, null: false
  end
end
