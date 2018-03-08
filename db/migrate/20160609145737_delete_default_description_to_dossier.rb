class DeleteDefaultDescriptionToDossier < ActiveRecord::Migration[5.2]
  class Dossier < ApplicationRecord
  end

  class Champ < ApplicationRecord
  end

  class Procedure < ApplicationRecord
  end

  class TypeDeChamp < ApplicationRecord
  end

  def up
    Procedure.all.each do |procedure|
      # change all type_de_champ place_order by +1 to insert new type_de_champ description on first place
      TypeDeChamp.where(procedure_id: procedure.id).each do |type_de_champ|
        type_de_champ.order_place += 1
        type_de_champ.save
      end

      # insert type_de_champ description on first place
      TypeDeChamp.create(libelle: 'Description', description: 'Description de votre demande', type_champ: 'textarea', order_place: 0, procedure_id: procedure.id, mandatory: true)
    end

    Dossier.all.each do |dossier|
      # get the new type de champ
      new_type_de_champ = TypeDeChamp.where(libelle: 'Description', type_champ: 'textarea', order_place: 0, procedure_id: dossier.procedure_id, mandatory: true)

      # create a new champ with the actual description value
      Champ.create(value: dossier.description, type_de_champ_id: new_type_de_champ.first.id, dossier_id: dossier.id)
    end

    remove_column :dossiers, :description
  end

  def down
    add_column :dossiers, :description, :text

    Champ.destroy_all(dossier_id: 0)

    TypeDeChamp.where(libelle: 'Description', type_champ: 'textarea', order_place: 0, mandatory: true).each do |type_de_champ|
      Champ.where(type_de_champ_id: type_de_champ.id).each do |champ|
        dossier = Dossier.find(champ.dossier_id)
        dossier.description = champ.value
        dossier.save

        champ.delete
      end

      procedure_id = type_de_champ.procedure_id
      type_de_champ.delete

      TypeDeChamp.where(procedure_id: procedure_id).each do |type_de_champ_2|
        type_de_champ_2.order_place -= 1
        type_de_champ_2.save
      end
    end
  end
end
