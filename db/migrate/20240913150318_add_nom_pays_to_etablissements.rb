# frozen_string_literal: true

class AddNomPaysToEtablissements < ActiveRecord::Migration[7.0]
  def change
    add_column :etablissements, :nom_pays, :string
  end
end
