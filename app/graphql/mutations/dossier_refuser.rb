module Mutations
  class DossierRefuser < Mutations::BaseMutation
    include DossierHelper

    description "Refuser le dossier."

    argument :dossier_id, ID, "Dossier ID", required: true, loads: Types::DossierType
    argument :instructeur_id, ID, "Instructeur qui prend la décision sur le dossier.", required: true, loads: Types::ProfileType
    argument :motivation, String, required: true
    argument :justificatif, ID, required: false

    field :dossier, Types::DossierType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(dossier:, instructeur:, motivation:, justificatif: nil)
      if dossier.en_instruction?
        dossier.refuser!(instructeur, motivation, justificatif)

        { dossier: dossier }
      else
        { errors: ["Le dossier est déjà #{dossier_display_state(dossier, lower: true)}"] }
      end
    end

    def authorized?(dossier:, instructeur:, motivation:, justificatif: nil)
      instructeur.is_a?(Instructeur) && instructeur.dossiers.exists?(id: dossier.id)
    end
  end
end
