class ConvertAllDatetimeToDateOnDatabase < ActiveRecord::Migration

  class TypeDeChamp < ActiveRecord::Base

  end

  def change
    TypeDeChamp.all.each do |type_de_champ|
      if type_de_champ.type_champ == 'datetime'
        type_de_champ.type_champ = 'date'
        type_de_champ.save
      end
    end
  end
end
