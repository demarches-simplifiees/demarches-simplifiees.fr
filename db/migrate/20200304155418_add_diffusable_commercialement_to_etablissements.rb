# frozen_string_literal: true

class AddDiffusableCommercialementToEtablissements < ActiveRecord::Migration[5.2]
  def change
    add_column :etablissements, :diffusable_commercialement, :boolean
  end
end
