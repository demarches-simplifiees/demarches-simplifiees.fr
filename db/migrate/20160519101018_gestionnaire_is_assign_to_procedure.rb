class GestionnaireIsAssignToProcedure < ActiveRecord::Migration
  class AssignTo < ApplicationRecord
    belongs_to :gestionnaire
    belongs_to :procedure
  end

  class Gestionnaire < ApplicationRecord
    has_and_belongs_to_many :administrateurs
    has_many :procedures, through: :assign_to
  end

  class Administrateur < ApplicationRecord
    has_and_belongs_to_many :gestionnaires
    has_many :procedures
  end

  class Procedure < ApplicationRecord
    belongs_to :administrateur
    has_many :gestionnaires, through: :assign_to
  end

  def change
    create_table :assign_tos, id: false do |t|
      t.belongs_to :gestionnaire, index: true
      t.belongs_to :procedure, index: true
    end

    Administrateur.all.each do |administrateur|
      administrateur.gestionnaires.each do |gestionnaire|
        administrateur.procedures.each do |procedure|
          AssignTo.create gestionnaire: gestionnaire, procedure: procedure
        end
      end
    end
  end
end
