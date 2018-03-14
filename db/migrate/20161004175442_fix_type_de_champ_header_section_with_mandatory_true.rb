class FixTypeDeChampHeaderSectionWithMandatoryTrue < ActiveRecord::Migration[5.2]
  class TypeDeChamp < ApplicationRecord
  end

  def change
    TypeDeChamp.all.each do |type_de_champ|
      type_de_champ.update_column(:mandatory, false) if type_de_champ.type_champ == 'header_section'
    end
  end
end
