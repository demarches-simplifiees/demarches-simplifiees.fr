module Mutations
  class DossierRefuserMutation < Mutations::BaseMutation
    argument :dossier_id, ID, required: true, loads: Types::DossierType
    argument :motivation, String, required: true

    field :dossier, Types::DossierType, null: true

    def resolve(dossier:, motivation:)
      dossier.change_state_with_motivation(:refuse, motivation)

      { dossier: dossier }
    end
  end
end
