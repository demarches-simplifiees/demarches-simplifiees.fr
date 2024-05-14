# frozen_string_literal: true

class AddSVASVRToProcedures < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :sva_svr, :jsonb, default: {}, null: false
  end
end
