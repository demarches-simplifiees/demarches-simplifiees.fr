module Types::Champs
  class SiretChampType < Types::BaseObject
    implements Types::ChampType

    field :etablissement, Types::PersonneMoraleType, null: true

    def etablissement
      if object.etablissement_id.present?
        etablissement = dataloader.with(Sources::RecordById, Etablissement).load(object.etablissement_id)
        etablissement unless etablissement&.as_degraded_mode?
      end
    end
  end
end
