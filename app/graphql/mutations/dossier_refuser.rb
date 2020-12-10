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
      dossier.refuser!(instructeur, motivation, justificatif)

      { dossier: dossier }
    end

    def ready?(justificatif: nil, **args)
      if justificatif.present?
        validate_blob(justificatif)
      else
        true
      end
    end

    def authorized?(dossier:, instructeur:, **args)
      if !dossier.en_instruction?
        return false, { errors: ["Le dossier est déjà #{dossier_display_state(dossier, lower: true)}"] }
      end
      dossier_authorized_for?(dossier, instructeur)
    end
  end
end
