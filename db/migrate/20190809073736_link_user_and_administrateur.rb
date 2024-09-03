# frozen_string_literal: true

class LinkUserAndAdministrateur < ActiveRecord::Migration[5.2]
  def change
    add_reference :users, :administrateur, index: true
    add_foreign_key :users, :administrateurs
  end
end
