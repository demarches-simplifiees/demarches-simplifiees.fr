module Mutations
  class DossierPasserEnInstructionMutation < Mutations::BaseMutation
    argument :dossier_id, ID, required: true, loads: Types::DossierType
    argument :instructeur_id, ID, required: true, loads: Types::ProfileType

    field :dossier, Types::DossierType, null: true
    field :errors, [String], null: false

    def resolve(dossier:, instructeur:)
      instructeur.follow(dossier)
      dossier.en_instruction!

      { dossier: dossier }
    end
  end
end
