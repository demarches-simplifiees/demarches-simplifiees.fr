# frozen_string_literal: true

class AddDateInFutureOptionToTypesDeChamp < ActiveRecord::Migration[7.1]
  def up
    # Ajouter l'option date_in_future (désactivée par défaut) pour tous les types de champ date et datetime existants
    TypeDeChamp.where(type_champ: ['date', 'datetime']).find_each do |type_de_champ|
      options = type_de_champ.options || {}
      options['date_in_future'] = '0' unless options.key?('date_in_future')
      type_de_champ.update_column(:options, options)
    end
  end

  def down
    # Supprimer l'option date_in_future de tous les types de champ
    TypeDeChamp.where(type_champ: ['date', 'datetime']).find_each do |type_de_champ|
      options = type_de_champ.options || {}
      options.delete('date_in_future')
      type_de_champ.update_column(:options, options)
    end
  end
end
