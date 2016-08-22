class FixDefaultTypeOnTypeDeChampTable < ActiveRecord::Migration
  class TypeDeChamp < ActiveRecord::Base

  end

  def up
    TypeDeChamp.where("private = false").update_all("type = 'TypeDeChampPublic'")
    TypeDeChamp.where("private = true").update_all("type = 'TypeDeChampPrivate'")
    remove_column :types_de_champ, :private
  end

  def down
    add_column :types_de_champ, :private, :boolean, default: true
    TypeDeChamp.where("type = 'TypeDeChampPublic'").update_all("private = false")
    TypeDeChamp.where("type = 'TypeDeChampPrivate'").update_all("private = true")
  end
end
