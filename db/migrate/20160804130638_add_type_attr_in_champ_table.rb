class AddTypeAttrInChampTable < ActiveRecord::Migration[5.2]
  class TypeDeChamp < ApplicationRecord
    has_many :champs
  end

  class Champ < ApplicationRecord
    belongs_to :type_de_champ
  end

  def up
    add_column :champs, :type, :string

    Champ.all.each do |champ|
      type = 'ChampPublic' if champ.type_de_champ.class == TypeDeChampPublic
      type = 'ChampPrivate' if champ.type_de_champ.class == TypeDeChampPrivate

      champ.update_attribute(:type, type)
    end
  end

  def down
    remove_column :champs, :type
  end
end
