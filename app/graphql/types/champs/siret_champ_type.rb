# frozen_string_literal: true

module Types::Champs
  class SiretChampType < Types::BaseObject
    implements Types::ChampType

    field :etablissement, Types::PersonneMoraleType, null: true

    def etablissement
      Loaders::Association.for(object.class, :etablissement).load(object)
        .then { |etablissement| etablissement unless etablissement&.as_degraded_mode? }
    end
  end
end
