# frozen_string_literal: true

class CreateExports < ActiveRecord::Migration[5.2]
  def change
    create_table :exports do |t|
      t.string :format, null: false

      t.timestamps
    end
  end
end
