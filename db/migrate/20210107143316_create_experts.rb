# frozen_string_literal: true

class CreateExperts < ActiveRecord::Migration[6.0]
  def change
    create_table :experts do |t| # rubocop:disable Style/SymbolProc
      t.timestamps
    end
  end
end
