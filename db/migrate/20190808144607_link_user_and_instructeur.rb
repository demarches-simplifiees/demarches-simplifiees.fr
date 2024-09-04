# frozen_string_literal: true

class LinkUserAndInstructeur < ActiveRecord::Migration[5.2]
  def change
    add_reference :users, :instructeur, index: true
    add_foreign_key :users, :instructeurs
  end
end
