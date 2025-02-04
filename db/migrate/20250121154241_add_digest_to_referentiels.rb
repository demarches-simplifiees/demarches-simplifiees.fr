# frozen_string_literal: true

class AddDigestToReferentiels < ActiveRecord::Migration[7.0]
  def change
    add_column :referentiels, :digest, :string
  end
end
