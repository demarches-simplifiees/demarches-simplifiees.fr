# frozen_string_literal: true

module Types::Champs
  class SiretChampType < Types::BaseObject
    implements Types::ChampType

    field :etablissement, Types::PersonneMoraleType, null: true

    def etablissement
      if object.etablissement_id.present?
        Loaders::Record.for(Etablissement).load(object.etablissement_id).then do |etablissement|
          etablissement unless etablissement&.as_degraded_mode?
        end
      end
    end
  end
end
