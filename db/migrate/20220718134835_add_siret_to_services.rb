# frozen_string_literal: true

class AddSiretToServices < ActiveRecord::Migration[6.1]
  def change
    add_column :services, :siret, :string
  end
end
