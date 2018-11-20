module Mutations
  class DossierAccepterMutation < Mutations::BaseMutation
    argument :dossier_id, ID, required: true, loads: Types::DossierType
    argument :motivation, String, required: true

    field :dossier, Types::DossierType, null: false

    def resolve(dossier:, motivation:)
      dossier.change_state_with_motivation(:accepte, motivation)

      { dossier: dossier }
    end
  end
end
