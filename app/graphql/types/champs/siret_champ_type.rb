# frozen_string_literal: true

module Types::Champs
  class SiretChampType < Types::BaseObject
    implements Types::ChampType

    field :etablissement, Types::PersonneMoraleType, null: true

    def etablissement
      dataloader.with(Sources::Association, :etablissement).load(object)
    end
  end
end
