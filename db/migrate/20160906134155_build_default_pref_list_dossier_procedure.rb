class BuildDefaultPrefListDossierProcedure < ActiveRecord::Migration[5.2]
  class Gestionnaire < ApplicationRecord
    has_many :assign_to, dependent: :destroy
    has_many :procedures, through: :assign_to
    has_many :preference_list_dossiers
  end

  class PreferenceListDossier < ApplicationRecord
    belongs_to :gestionnaire
    belongs_to :procedure
  end

  class AssignTo < ApplicationRecord
    belongs_to :procedure
    belongs_to :gestionnaire
  end

  class Procedure < ApplicationRecord
    has_many :gestionnaires, through: :assign_to
    has_many :preference_list_dossiers
  end

  def up
    Gestionnaire.all.each do |gestionnaire|
      gestionnaire.procedures.each do |procedure|
        gestionnaire.preference_list_dossiers.where(procedure: nil).each do |preference|
          clone = preference.dup

          clone.procedure = procedure
          clone.save
        end

        base_object = gestionnaire.preference_list_dossiers.where(procedure: nil).size
        created_object = gestionnaire.preference_list_dossiers.where(procedure: procedure).size

        raise "ERROR nb object (#{base_object} != #{created_object})" if created_object != base_object
      end
    end
  end

  def down
    PreferenceListDossier.where('procedure_id IS NOT NULL')
  end
end
