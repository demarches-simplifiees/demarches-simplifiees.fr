module Mutations
  class DossierRepasserEnConstructionMutation < Mutations::BaseMutation
    argument :dossier_id, ID, required: true, loads: Types::DossierType

    field :dossier, Types::DossierType, null: true

    def resolve(dossier:)
      dossier.en_construction!

      { dossier: dossier }
    end
  end
end
