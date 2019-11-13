module Mutations
  class DossierPasserEnInstruction < Mutations::BaseMutation
    include DossierHelper

    description "Passer le dossier en instruction."

    argument :dossier_id, ID, "Dossier ID", required: true, loads: Types::DossierType
    argument :instructeur_id, ID, "Instructeur qui prend la décision sur le dossier.", required: true, loads: Types::ProfileType

    field :dossier, Types::DossierType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(dossier:, instructeur:)
      if dossier.en_construction?
        dossier.passer_en_instruction!(instructeur)

        { dossier: dossier }
      else
        { errors: ["Le dossier est déjà #{dossier_display_state(dossier, lower: true)}"] }
      end
    end

    def authorized?(dossier:, instructeur:)
      instructeur.is_a?(Instructeur) && instructeur.dossiers.exists?(id: dossier.id)
    end
  end
end
