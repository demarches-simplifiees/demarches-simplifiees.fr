module Mutations
  class DossierRepasserEnInstruction < Mutations::BaseMutation
    include DossierHelper

    description "Passer le dossier en instruction."

    argument :dossier_id, ID, "Dossier ID", required: true, loads: Types::DossierType
    argument :instructeur_id, ID, "Instructeur qui prend la décision sur le dossier.", required: true, loads: Types::ProfileType
    argument :disable_notification, Boolean, "Désactiver l’envoi de l’email de notification après l’opération", required: false, default_value: false

    field :dossier, Types::DossierType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(dossier:, instructeur:, disable_notification:)
      dossier.repasser_en_instruction!(instructeur: instructeur, disable_notification: disable_notification)

      { dossier: dossier }
    end

    def authorized?(dossier:, instructeur:, **args)
      unless dossier.accepte? || dossier.refuse? || dossier.sans_suite?
        return false, { errors: ["Le dossier ne peut repasser en instruction lorsqu'il est #{dossier_display_state(dossier, lower: true)}"] }
      end
      dossier_authorized_for?(dossier, instructeur)
    end
  end
end
