# frozen_string_literal: true

class AddRemindedAtToAvis < ActiveRecord::Migration[6.1]
  def change
    add_column :avis, :reminded_at, :datetime
  end
end
