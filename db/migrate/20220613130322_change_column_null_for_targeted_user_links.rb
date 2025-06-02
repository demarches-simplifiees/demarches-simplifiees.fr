# frozen_string_literal: true

class ChangeColumnNullForTargetedUserLinks < ActiveRecord::Migration[6.1]
  def change
    safety_assured { change_column_null :targeted_user_links, :user_id, true }
  end
end
