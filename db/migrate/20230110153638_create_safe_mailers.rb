# frozen_string_literal: true

class CreateSafeMailers < ActiveRecord::Migration[6.1]
  def change
    create_table :safe_mailers do |t|
      t.string :forced_delivery_method

      t.timestamps
    end
  end
end
