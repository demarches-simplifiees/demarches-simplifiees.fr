class AdminHasAndBelongGestionnaire < ActiveRecord::Migration[5.2]
  class Gestionnaire < ApplicationRecord
  end

  class AdministrateursGestionnaire < ApplicationRecord
  end

  def up
    create_table :administrateurs_gestionnaires, id: false do |t|
      t.belongs_to :administrateur, index: true
      t.belongs_to :gestionnaire, index: true
    end

    Gestionnaire.all.each do |gestionnaire|
      execute "insert into administrateurs_gestionnaires (gestionnaire_id, administrateur_id) values (#{gestionnaire.id}, #{gestionnaire.administrateur_id}) "
    end

    remove_column :gestionnaires, :administrateur_id
  end

  def down
    add_column :gestionnaires, :administrateur_id, :integer

    AdministrateursGestionnaire.all.each do |ag|
      gestionnaire = Gestionnaire.find(ag.gestionnaire_id)
      gestionnaire.administrateur_id = ag.administrateur_id
      gestionnaire.save
    end

    drop_table :administrateurs_gestionnaires
  end
end
