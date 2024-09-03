# frozen_string_literal: true

class LinkUserAndExpert < ActiveRecord::Migration[6.0]
  def change
    add_reference :users, :expert, index: true
    add_foreign_key :users, :experts
  end
end
