# frozen_string_literal: true

class AddEnseigneToEtablissements < ActiveRecord::Migration[6.0]
  def change
    add_column :etablissements, :enseigne, :string
  end
end
